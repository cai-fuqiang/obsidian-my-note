# 背景

![PVM引入背景](PVM-引入背景.md)

在介绍PVM之前，我们先看下嵌套虚拟化的细节，以及嵌套虚拟化的问题。
# 嵌套虚拟化实现

目前最好的嵌套虚拟化，是尽量复用 VMX 来加速，在介绍嵌套虚拟化之前，我们先来看下VMX 的主要功能，以及其如何加速的。
## VMX 扩展

虚拟化主要模拟的三剑客:
* CPU
* memory
* interrupt
### cpu
intel/AMD 为了加速虚拟机的一些操作，例如 异常, 系统调用等处理, 避免world switch, 引入了 VMX 扩展:
[[VMX 扩展.excalidraw#^fkGaA3v2|VMX CPU]]

![[VMX 扩展.excalidraw|600]]
* CPU模式上面，在 RING 基础上，又增加了一个模式 vmx root/non-root operation，其中 Guest 运行在 non-root operation, Host 运行在 root operation.
* 增加VMCS
	* 控制VM行为
	* 在VMX root/non-root operation 切换时 save/load guest host 上下文
	* 保存VM-exit的信息
* VMX增加了一些指令集:
	* vmxoff,vmxon: 用来打开关闭vmx
	* vmlanch, vmresume: 用于VMX root operation(kvm) 切换到 VMX non-root operation
	* vmread/vmwrite：用于KVM访问VMCS
	* vmcall: 常用作半虚拟化

### mem

而在内存虚拟化加速层面， 使用EPT feature。

```ad-important
内存虚拟化的工作主要在于地址转换。地址转换的主要工作指导MMU是将VA转换成PA，在虚拟化场景下(single-level), 有两层转换关系:
* GVA->GPA
* GPA->HPA
  
而为了完成上面的两级转换, 方法有:
* 使用两层页表，每层页表指示一层转换关系.(EPT)
* 压缩页表: 将两个页表转换成一层页表(SPT)
```

EPT 主要提供第二级页表。

![[mem.excalidraw|1000]]
在没有EPT的情况下, **mmu 硬件只能walk ==一层==页表**。所以需要使用页表压缩的方式（也就是影子页表)。使用影子页表，需要捕获虚拟机`#PF`, 然后走guest page table walk 的流程，根据guest Page Table得到`GVA->GPA` 的映射关系，在加上KVM掌握的 `GPA->HPA`的映射关系，构建出可以映射 `GVA->HPA`的shadow page table，VMCS中的gCR3也指向该SPT。

而有EPT的情况下, **mmu 硬件能walk ==两层==页表**，每层负责转换一层映射关系。而 EPT负责 **`GPA->HPA`** 的转换。VMCS中的gCR3指向guest中的page table。当硬件mmu 做地址转换时，首先从CR3获取 GPT(pml4)位置，然后走Guest Page Table walk获取到GPA，然后从 EPTP获取 PML4E地址，然后走 EPT Page Table walk,最终获取到HPA，整个过程无需由硬件自己完成。

**_和影子页表相比，为什么EPT能大大加速内存虚拟化_**

影子页表最大的问题在于,  影子页表中需要关心`GVA->GPA`(通过GPT) ，而Guest Page Table是会经常改变的，KVM的维护逻辑有两个:
* sync: 在SPT中同步GPT更改（往往是通过写保护的方式)
* unsync: 在SPT中不同步GPT的更改，让SPT的行为和TLB类似，等待TLB flush 时再同步GPT

**无论是那种方式，在Guest中由于经常起停用户态程序，用户态程序也会申请/释放内存，==`GVA->GPA`的映射关系经常变动==，这种变动会引起 `#PF` 而trap 到 Host。**

但是, EPT中仅需要关心, `GPA->HPA`, 如果不考虑 swap, ksm, thp等功能。`GPA->HPA`的映射往往是不变的。所以EPT一旦建立，几乎不会在发生更改。**所以这种映射关系的建立更像是 ==一次性工作==。==大大减少了 VM EXIT 次数==**。

### interrupt

interrupt 我们不做过多介绍(因为自己还没有看 interrupt nested 代码 #TODO, 所以这部分我们也先略过)，其加速方向主要有两个:
* 减少APIC reg访问带来的vm-exit。
* 减少/避免虚拟中断的注入带来的VM-exit。

## nested virtialization

同样，我们分为三部分: CPU memory interrupt, 而在嵌套虚拟化场景下，内存测试性能下降最为严重。

![[nested virt中内存性能下降严重]]

另外，我们将不同层次的操作系统简称如下:

| Lx  | 表示                   |
| --- | -------------------- |
| L0  | Host                 |
| L1  | 在Host启动的**第一层虚拟机**   |
| L2  | 在第一层虚拟机启动的**第二层虚拟机** |
### CPU virtualization with nested

前面我们介绍过，VMX额外引入了两个CPU model:
* VMX root operation: Run Host
* VMX non-root operation: Run Guest

但是在嵌套虚拟化场景下，Guest分为L1, L2两层，如何模拟L2呢？论文<sup>1</sup> 提供了仍然利用VMX 来加速。而L1 "负责" 使用VMX 管理L2, 那就必须让L1 能够识别/使用 VMX。而VMX 本身不支持嵌套虚拟化。所以需要L0来模拟这部分功能，主要有:
* VMX instruction 模拟
* 维护VMCS
* vm-exit 转发
* 内存虚拟化(在内存虚拟化章节中讲述)
* 中断虚拟化(在中断虚拟化章节中讲述)


**_VMX instruction模拟_**

由于VMX不支持嵌套虚拟化，所以L1 执行的VMX instruction 由L0模拟. 主要看下面几个命令模拟:
* **VMLANCH/VMRESUME**: 当L1执行`VMRESUME`时，退回L0, L0负责准备好L2执行的VMCS(VMCS02), 然后再执行 `VMLANCH/VMRESUME`, 由L0直接进入L2.
* **VMREAD/VMWRITE**:   当L1 执行VMREAD,VMWRITE时，直接访问 shadow VMCS而不VM-exit

**_维护VMCS_**

在L2, L0中一共存在4个VMCS

| VMCSxx      | 维护者 | 作用                                              |
| ----------- | --- | ----------------------------------------------- |
| VMCS01      | L0  | 用于L0切换L1 使用                                     |
| VMCS12      | L1  | 供L0参考来制作VMCS02                                  |
| **VMCS02**  | L0  | 用于L0切换L2使用, (但是VMCS02也包含VMCS01的控制信息下面会讲)        |
| shadow VMCS | L0  | 当L1 执行VMREAD,VMWRITE时，直接访问 shadow VMCS而不VM-exit |

![[nested VMCS.excalidraw|600]]
`VMCS02` 中某些字段(例如 Guest State area) 可以从VMCS12中直接获取，无需转化，但是某些字段需要结合`VMCS01, VMCS12`转换称一个合适的值（例如execution area)填入VMCS02。

```ad-tip
title: VMCS12, VMCS01中 CR3 store exiting 和 external intr exit, 在VMCS02中会做类似于"合并"的操作。
```

**_vm-exit 转发_**
当Guest触发VM-exit时, 会直接trap到 VMX root operation, 而在嵌套虚拟化场景中，VMX root operation 由L0运行(L1 运行在VMX non-root operation)。而属于L2 的VM-exit应该由L1处理，所以这时候，需要L0将该VM-exit
event 转发到L1。(下图中红色部分描述VM-exit转发步骤，而下图中的绿色部分，则描述`VMRESUME/VMLAUCH` 指令模拟过程)

![[VM-exit forward.excalidraw|600]]
### mem virtualization with nested

前面提到过在支持EPT的情况下，MMU会walk 一个多级页表，其中EPT位于second level，但是**EPT只有一级，并不支持多级**。而每一层级页表只能反映一个映射关系。在嵌套虚拟化场景下，映射链如下:

![[嵌套虚拟化中地址转换]]

EPT层级不够，怎么办呢? 前面提到过，方法有两种:
* 硬件支持多层级(目前EPT 只支持额外一级)
* **==页表压缩==**

```ad-note
title: 因为x86 EPT支持的比较早，大部分的云厂的硬件都支持EPT，所以下面我们就以Host支持EPT来描述具体场景。
```

具体有两种方法:

| method                                       | 压缩哪部分映射                                              | in other word                   |
| -------------------------------------------- | ---------------------------------------------------- | ------------------------------- |
| [[nested mem virt - SPT-on-EPT\|SPT-on-EPT]] | GVA<sub>L2</sub>->GPA<sub>L2</sub>->GPA<sub>L1</sub> | L1当EPT feature 不存在，在L1中使用影子页表   |
| [[nested mem virt - EPT-on-EPT\|EPT-on-EPT]] | GPA<sub>L2</sub>->GPA<sub>L1</sub>->HPA<sub>L0</sub> | L0中使用影子页表，只不过影子EPT<sub>12</sub> |
![[内存嵌套虚拟化两种实现性能均不佳]]

(主要体现 触发了很多 world switch(VMENTRY/VMEXIT), 而这些很多是直接trap到L0, L0仅起到一个转发的作用)

我们来具体看下两种内存虚拟化的方式具体的world switch细节。

#### SPT-on-EPT
![[sosp2023-pvm-paper.pdf#page=5&rect=39,538,290,732|sosp2023-pvm-paper, p.5]]
主要分两个阶段:
1. [[SPT-on-EPT建立GPT阶段触发PF#PF处理流程|L2建立页表阶段]]
2. L2建立完页表, 但是leaf SPT中并未填入具体物理页而导致`#PF`, 这时L1会补全GPT<sub>L1</sub> 以及 SPT, 其在[[SPT-on-EPT二阶段和一阶段不同的点|这些步骤有些不同(4,7)]]。

![[SPT-on-EPT最坏情况下world switch总次数]]

```ad-tip
[[SPT readonly是导致一阶段world switch 主要因素]]
```
#### EPT-on-EPT
![[sosp2023-pvm-paper.pdf#page=5&rect=314,538,571,737|sosp2023-pvm-paper, p.5]]

> [!PDF|red] [[sosp2023-pvm-paper.pdf#page=5&selection=483,0,485,5&color=red|📖 |EPT-on-EPT是当前最优秀的 nested memory virtualization 实现]]

其工作也分两个阶段:
* [[EPT-on-EPT第一阶段| 构建 EPT12]]
* [[EPT-on-EPT第二阶段工作|根据 EPT01 && EPT12 构建 EPT02]]

EPT-on-EPT优点和不足:
* [[EPT-on-EPT优点| 优点:  L2 更新 GPT2不会再发生 world switch]]
* [[EPT-on-EPT不足|不足: build 和 update EPT02仍然需要 world switch]]

![[EPT-on-EPT world switch总次数]]

对比两者的world switch次数，可以得到一个结论

```ad-summary
[[EPT-on-EPT在最差情况下，world switch 远比SPT-on-EPT 少]]
```

```ad-question
title: 除了在最差情况下 EPT-on-EPT world switch少，还有没有其他优秀的地方?
A: `SPT-on-EPT`的本质是在L1中 影子 GPT, `EPT-on-EPT`本质是在L0中影子 EPT<sub>12</sub>, 前面提到过EPT的用来指示 GPA->HPA的映射(对于L1来说，是GPA<sub>L2</sub>->GPA<sub>L1</sub>), 在大部分的情况下，这部分映射几乎是不变的，也就是说，EPT shadow page table一旦建立，其基本不会在改变。而GVA不同，其经常会变动，所以因页表变动造成的world switch要多很多。
```

```ad-warning
title: 在有多个虚拟机的情况下, L0 会 shadow 全部vm的EPT么? 这岂不是要内存占用爆炸?
并不是, L0 只会 shadow近期访问的几个VM的EPT tree!!!(==**关键!!, 因为安全容器需要启动很多虚拟机**==)
```

#### summary of existing mem virt

![[EPT-on-EPT的缺点总结]]
### interrupt virtualization with nested

(暂不关注 #TODO )
## summary of nested virt
* [[嵌套虚拟化中硬件加速不明显，甚至可能起到反作用]]
* [[目前嵌套虚拟化的设计需求并不贴合以IAAS为底座的安全容器的场景]] ==**(关键)**==

<font color="#ff0000"><mark style="background:#b1ffff">So, create PVM to solve it!!</mark></font>
# PVM
## overview
* 什么是PVM?
  ![[PVM概述]]
* PVM 目标?
  ![[PVM目标- 轻量, 简单，高效]]
* PVM组成
  ![[PVM三大组件]]
  [[PVM 涉及的两个Hypervisor 内核模块|hypervisor涉及两个内核模块: kvm.ko, kvm-pvm.ko]]
* 设计简述
  ![[PVM 设计简述]] 
## PVM implement
### PVM CPU virt  - base vring

![[PVM中L1 hypervisor, L2 用户态程序, L2 内核在ring中的位置]]

### PVM swither

**swither** 从字面意思上看，就是去切换上下文。那
```ad-question
title: switch what?
[[PVM switch what|world switch && guest vring switch]]
```

![[PVM switcher 映射位置]]
并且, [[switcher 需要在多个地址空间中映射相同地址原因|switcher 需要在多个地址空间中映射相同地址]]

另外, ![[switcher 仿照 xen & lguest 等现有半虚拟化 架构设计，并做了改进]]
```ad-note
title: 软件虚拟化的隔离肯定没有硬件好。所以PVM在这个方面做了很多努力(安全容器的一个重要诉求，就是提升不同容器的隔离性)
```


![[switcher 组成包括高效简洁的汇编代码和数据结构]]
关键结构:
*  per-cpu系统调用条目，用于处理 L1 来宾管理程序、L2 来宾用户和 L2 内核之间的系统调用请求
*  per-cpu CPU 切换器状态，类似于 VMCS，它在世界切换期间保存和恢复 L2 来宾和 L1 主机状态
* 用于捕获中断/异常的定制中断描述符表 (IDT) 处理程序(**PVM 修改 L2 来宾（用户和内核）地址空间中的 IDT 条目，以指向切换器的自定义中断处理程序。==这允许切换器捕获所有外部中断或异常==**)

由于在L1中没有硬件辅助(VMX), 所以 trap to hypervisor 有两种情况:
* syscall/hypercall
* intr/exception
而PVM有两种方式去处理上面引起的切换（也就是VM-entry, VM-exit)

第一种方式，是通过switcher trap 到hypervisor，有hypervisor 模拟trap 的指令(syscall, hypercall), 或者intr.
![[sosp2023-pvm-paper.pdf#page=7&rect=313,554,555,722|sosp2023-pvm-paper, p.7]]
简单来说，当guest执行syscall或者遇到exception时, 进入swithcer执行`to_hypervisor`函数，`to_hypervisor`
函数负责保存Guest上下文，然后trap到Hypervisor 模拟. 而Hypervisor做完模拟后。进入switcher 调用`enter_guset` 再负责恢复guest上下文进入guest。

第二种方式, ==direct switch==:
![[sosp2023-pvm-paper.pdf#page=8&rect=59,575,290,735|sosp2023-pvm-paper, p.8]]
direct switch 核心思想是:L2 用户和 L2 内核都在 h_ring3,切换它们的本质只是换一套寄存器、页表、栈——**==这件事 switcher 自己就能做,不需要惊动 L1 hypervisor==**。

* 用户-> 内核 (syscall)
  当 L2 用户执行 syscall 指令时,CPU 从 h_ring3 跳到 h_ring0,进入 switcher。switcher 做三件事:
	1.  保存 L2 用户当前的 CPU 状态;
	2. 恢复之前保存的 L2 内核状态;
	3. 构造一个 syscall 调用帧,让 L2 内核能拿到系统调用的参数。**做完这些之后, ==switcher 直接跳转到 L2 内核去执行——全程没有经过 L1 hypervisor==**
* 内核 → 用户(syscall 返回)
  正常的 Linux 内核用 sysret 指令从系统调用返回。但 sysret 是一条特权指令,而 L2 内核跑在 h_ring3,执行它就会触发异常、陷入 h_ring0。如果走常规路径,这个异常又要经过 L1 hypervisor 来处理。
  
  PVM 的解决办法是: **把 L2 内核里的 sysret 替换成一个 sysret hypercall。==当 L2 内核想返回用户态时,发这个 hypercall,它直接进入 switcher(不经过 L1 hypervisor),switcher 把执行环境切回 L2 用户态,直接返回==**
### PVM mem virt  - PVM-on-EPT

L0 没有硬件辅助, 就只能使用 SPT, 前面提到过, **SPT-on-EPT的性能非常差。==所以PVM基于SPT增加了很多优化方法，形成一种高效的SPT方法，称为PVM-on-EPT==**。

![[sosp2023-pvm-paper.pdf#page=8&rect=321,560,542,734|sosp2023-pvm-paper, p.8]]
* 更便宜的world switch
  这是PVM-on-EPT最根本的优势。在EPT-on-EPT中，一次 `#PF` 要 $2n+6$ 次 world switch, **每次切换都会在`VMX non-root operation && VMX root operation` 中切换，==这个切换时非常昂贵的==**。**但是 `PVM-on-EPT`将`#PF`的处理完全限定在==L1== 中**, 仅需要 $2n+4$次 world switch,  **更关键的是，由于仅涉及VMX non-root operation 中的 ring 切换，==处理平均延迟在 0.179us, 比 EPT-on-EPT 的 1.3us 快了一个数量级, 接近单层虚拟化的 0.105us==。**
* Prefault(预填充)优化
  在传统的页故障处理流程中,L2 内核更新完 GPT2 后通过 iret hypercall 返回时,如果直接切回 L2 用户态,后续访问刚更新的虚拟地址时还会再次触发 SPT12 上的页故障。**PVM 的 prefault 优化在 L2 内核返回时并不直接切回用户态,而是先切换到 L1,==由 PVM 主动、预先地更新 SPT12 中对应的映射条目==,然后再返回 L2 用户态**。这样消除了后续因 SPT12 缺失而产生的额外页故障。(**这个不是影子页表本身的优化么。。**)
* PCID优化
  <font color="#ff0000">嵌套虚拟化现状:</font> **在同一 L2 guest 中运行的==所有进程共享相同的更高粒度的 VPID==。这意味着任何到 ==L2（用户或内核）的 TLB 刷新都会导致更高粒度的 VPID 被刷新==，而不是特定的 PCID**，从而导致严重的性能损失
  <font color="#9bbb59">优化:</font> **引入 PCID映射机制——将 L1 中==未使用的 PCID(如 32–63)分配给 L2(32–47 给 guest ring0,48–63 给 guest ring3),并与 L2 自身的 PCID 做映射==**。这样 TLB 硬件就能识别 L2 内每个进程各自的 SPT,world switch 时不再需要刷新 TLB
* mmu_lock  ( #TODO 理解这块需要查看代码)
###  PVM interrupt virt
(略 #TODO )

# PVM 性能评估

## micro-benchmark

### VM-entry VM-exit 往返时间

![[sosp2023-pvm-paper.pdf#page=10&rect=309,615,565,736|sosp2023-pvm-paper, p.10]]
* 在single-level 中, PVM VM-entry VM-exit的处理时间 仅比 kvm 略慢
* 而对比`KVM(NST)`, `pvm (NST)`, 其速度要快接近一个数量级

### syscall
![[sosp2023-pvm-paper.pdf#page=11&rect=38,602,302,738|sosp2023-pvm-paper, p.11]]
* 在single-level pvm 没有direct-switch优化的情况下, pvm(BM)的性能比 kvm-ept要慢不少，但是在direct-switch的优化加持下，pvm的性能接近 kvm-ept。（KPTI enable)
* 而在嵌套虚拟化场景下，pvm比kvm 性能略低

### Page faults (重点)

![[sosp2023-pvm-paper.pdf#page=11&rect=302,601,568,751|sosp2023-pvm-paper, p.11]]
从这个图可以看到 `pvm(NST)` 比`kvm-ept`在扩展性上提升要高很多, 并且已经接近 `pvm(BM)`甚至 kvm-`ept(BM)`的性能
```ad-todo
* pvm(NST-prefault)
* pvm(NST-pcid)
* pvm(NST-lock)
和 pvm(NST)之间的关系是什么样的
```
## System Benchmarks

![[sosp2023-pvm-paper.pdf#page=12&rect=43,464,302,724|sosp2023-pvm-paper, p.12]]
* 大多数情况下，pvm (BM) 的性能始终优于 kvm-spt，除了 fork、exec 和 sh 之外，其性能与 kvm-ept (BM) 接近但稍差。
* 除了fork exec sh三个测试之外,  嵌套虚拟化 pvm (NST) 始终优于 kvm-ept (NST)

原因是:
**这三个基准测试集中==创建了新的页表，没有实际访问它们==。因此，这些基准测试会==导致guest page fault，而无需更新 L0 的 EPT==**。在这种情况下，硬件辅助方法总是更有效，并且页面错误可以由guest来单独处理。
***
另外 Table 4 中的后三项也是性能较差, 原因:

与 fork 基准测试类似，**在虚拟机管理程序管理的页表中没有更新的情况下会发生guest page fault**。我们还对网络延迟和带宽进行了测试，得到了与文件系统测试类似的结果。

```ad-note
title: 但是我个人认为，上面优势的kvm-ept(NST)测试项，会在安全容器场景下，也称为劣势(因为容器实例切换导致shadow EPT 被频繁zap)。
```


### real-world application

我们继续使用四个具有不同特征的代表性实际应用程序来评估 PVM：
* Kbuild [26] 从涉及计算和文件 I/O 混合的源头构建 Linux 内核； 
* Blogbench [16] 是一个文件系统基准测试，可以重现繁忙文件服务器的负载； 
* SPECjbb2005 [14] 是一个涉及 Java 虚拟机 (JVM) 使用的 Java 基准测试； 
* Fluidanimate 是一个基准测试，具有选自 PARSEC 基准测试套件 [21] 的大型数据集。

**运行了同一基准测试的多个实例，==每个实例都在一个单独的安全容器中==，并将并发级别从 1 更改为 16**
***
![[sosp2023-pvm-paper.pdf#page=13&rect=56,582,576,720|sosp2023-pvm-paper, p.13]]
首先，对于所有应用程序，**PVM 提供的性能==接近于单级虚拟化的硬件辅助方法(EPT(PM))==**。**此外，当并发量较高时，==kvm-ept (NST) 的性能在所有情况下都会崩溃==，这表明 L0 虚拟机管理程序成为瓶颈**。**这一发现进一步证明，==仅利用硬件辅助方法来遍历虚拟化堆栈中的多个层既不高效也不具有适应性==**。相比之下，PVM 始终实现了良好的性能，并且在许多情况下接近单级虚拟化的性能。**由于更有效地处理 HALT 指令，PVM 甚至优于 Fluidanimate 中的硬件辅助方法**。 PVM 通过超级调用执行 HALT 指令，并执行睡眠和唤醒过程，无需在非根模式和根模式之间切换，从而提高具有阻塞同步的并行程序的总体 CPU 利用率。

***

![[sosp2023-pvm-paper.pdf#page=13&rect=50,366,302,579|sosp2023-pvm-paper, p.13]]
**我们进一步将安全容器部署的密度提高到两个云实例可以处理的最大容量**。图 12 显示了 Fluidanimate 的性能——四个应用程序中内存消耗最大的一个。**有趣的是，在高负载条件下，除了 kvm-ept (NST) 之外，所有方法都收敛到相似的性能，==该方法由于无法连接到 RunD 容器运行时而崩溃==**。最后，我们使用 Cloud Bench Suite 中具有大型数据集的三个代表性工作负载评估PVM。**该实验压力测试了 PVM 在相对较低的并发级别执行数据密集型应用程序的能力。图 13 显示 ==PVM 的性能接近裸机方法，并且显着优于 kvm-ept (NST)**==。
## PVM  Evaluation summary(real world app)
![[PVM 性能评估总结- real world app]]

# PVM现状
* 商业应用
	* 应用云厂:  PVM 已被主要 **IaaS 云提供商==阿里云==采用，作为托管安全容器的==裸机实例==的替代方案**。
	* 应用规模: 目前，**PVM 每天运行超过 ==100K== 个安全容器和超过 ==400K 个 vCPU==**。
	* 应用负载类型多样:
		* 用户定义的无服务器函数
		* 通过 Spark 进行的数据分析以及离线批处理作业
		* 等等
	* 应用趋势
		* 在过去的一年里，**PVM 的采用持续增长**。**它导致 ==36% 的用户从裸机实例转向通用实例==，以实现安全的容器托管，并为云租户节省大量成本**。
	* 应用效果
		* 从裸机服务器到具有嵌套虚拟化的 PVM 服务器的内存数据处理和分析工作负载。**这些 PVM 服务器的 Spark 工作负载平均性能提升了 22.6%。值得注意的是，PVM服务器配备了比阿里云裸机更新一代的处理器。如果 PVM 部署在同一平台上，==我们预计 PVM 能够提供与裸机服务器相当的性能==**。
* 社区
	* patch 推到社区后，未被maintainer 合并。目前仅蚂蚁维护。（但是蚂蚁维护者很厉害，patch质量无需担心)
# 附录
* [[EPT-on-EPT 比 SPT-on-EPT 触发PF的总次数更少]]
* [[EPT-on-EPT 比 SPT-on-EPT 在每次PF时world switch 切换更少]]

# 参考链接
1. [[Ben-Yehuda-nested-virt.pdf|利用VMX实现嵌套虚拟化论文]]