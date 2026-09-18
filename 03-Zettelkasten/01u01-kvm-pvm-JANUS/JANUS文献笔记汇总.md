---
type: literature
status: reading
category:
summary:
created: 2026-09-18T15:34:56+08:00
modified: 2026-09-18T20:11:42+08:00
QA:
---

# summary

> [!summary]
> `= this.summary`

# 引用

> [!PDF|important] ![[osdi2026-janus-paper.pdf#page=3&rect=59,628,278,731|实现嵌套内存虚拟化的两种方式]]
> 1. SPT<sub>L1</sub>+EPT<sub>01</sub>: 压缩 GVA<sub>L2</sub>->GPA<sub>L2</sub>->GPA<sub>L1</sub> --> SPT<sub>L1</sub>
> 2. GPT<sub>L2</sub>+ EPT<sub>02</sub>: 压缩 GPA<sub>L2</sub>-> GPA<sub>L1</sub>-> HPA  ---> EPT<sub>02</sub>

^db6eb9

> [!PDF|] [[osdi2026-janus-paper.pdf#page=3&selection=215,24,261,21|📖 目前针对内存虚拟化需要同步页表的优化方案]]
> >  CKI [38] constructs GPTL2 to map GVAL2 directly to GPAL1 and leverages Supervisor Protection Keys (PKS) [30] to restrict L2’s memory access, thereby eliminating the need to maintain SPT . HyperTurtle [56] takes a different approach by allowing L1-registered eBPF programs to apply updates directly to EPT1→2 inside L0, removing the synchronization cost.
> >  
> * **CKI**: 优化 `SPT-on-EPT`中的SPT部分，可以直接将 GVA<sub>L2</sub>映射到 GPA<sub>L1</sub>, 并通过`PKS`技术来限制L2 内存访问.
> * **HyperTurtle**: 优化 `EPT-on-EPT`  。可以让L0直接修改EPT<sub>1->2</sub>, 从而避免同步开销。

> [!PDF|red] [[osdi2026-janus-paper.pdf#page=3&selection=261,22,264,25&color=red|📖无论是CKI, 还是HyperTurtle 都依赖严格的内存分配假设，在云原生场景难以满足]]

> [!PDF|note] [[osdi2026-janus-paper.pdf#page=3&selection=270,27,313,21&color=note|📖 JANUS 不在使用L0,L1主导的实现方法，而是让其各司其职，负责自己擅长的部分]]
> * L1 擅长 world switch: L0 world switch to L1 is CHEAPER!
> * L0 擅长 处理page fault: L0通过建立 EPT02, 可以建立 GPA<sub>L2</sub> ->HPA的映射，该映射关系更稳定。
> 其他引用:
> > [!PDF|important] [[osdi2026-janus-paper.pdf#page=7&selection=252,19,257,41&color=important|📖 JANUS separates these mechanisms by assigning the responsibilities of world switching and pagetable management to distinct hypervisors.]]

^d6a2fd

> [!PDF|note] [[osdi2026-janus-paper.pdf#page=3&selection=437,0,467,2&color=note|📖 JANUS 仍然使用 switcher 来拦截L2的虚拟化事件，从️而减少L0转发事件带来的不必要的性能损失]]
> 该行为和 `PVM` 相同

> [!PDF|important] [[osdi2026-janus-paper.pdf#page=3&selection=467,2,469,13&color=important|📖 另外 JANUS在world switch时，也将 memory view 切换]]
> 虽然PVM也会切换`memory view`，但是其是通过 `SPT`切换, 而JANUS则切换 EPT. 

> [!PDF|important] [[osdi2026-janus-paper.pdf#page=3&selection=469,14,514,39&color=important|📖  JANUS 实现 memory view switch 上的一些挑战以及优化]]
> > JANUS addresses this by using VMFUNC-based EPTP switching, allowing the processor to transition between the L1 view (EPT0→1) and the L2 view (EPT0→2) entirely within non-root mode (no L0 participation). Finally, to ensure these transitions remain isolated and tamper-proof, JANUS introduces a shadow-root mechanism that embeds control metadata within the nested guest’s page table, preventing a compromised L2 from subverting world-switch integrity.
> 
> 1. 切换`EPTP`是L0的职责，假如在`L0 <-> L1` 的过程中, 通过 TRAP L0来切换 EPTP, 那将造成一次昂贵的world switch。而 JANUS的方案，是利用 `VMFUNC EPTP switch` hardware feature来实现 EPT<sub>01</sub> <--> EPT<sub>02</sub> 之间的快速切换。
> 2. 为了确保 switcher的隔离与防篡改，JANUS引入了一种影子根机制，该机制将控制 GPT<sub>L2</sub> metadata来防止 破坏 switcher 完整性。

> [!PDF|important] ![[osdi2026-janus-paper.pdf#page=6&rect=310,587,568,728&color=important|📖 PVM-on-EPT VS EPT-on-EPT 执行 map()/unmap() 操作，并在 active/inactive physical memory 场景下测试的性能对比]]
> * EPT-on-EPT：更适合`Active PM` , 其会产生极少的 VM-exit, 而在 `Inactive PM`中，其因EPT<sub>02</sub>为映射，会产生大量的VM-exit(EPT violation), 而 修复 EPT violation 时，也会造成更多的world switch，例如模拟 VMRESUME。
> * PVM-on-EPT: 其在Inactive PM和 Active PM 产生的 Exit 次数相同（Inactive PM 耗时稍长，因为要trap L0 fix EPT<sub>01</sub>

^ea569b

> [!PDF|important] [[osdi2026-janus-paper.pdf#page=6&selection=363,0,374,27&color=important|📖 L0和L1 缺少 cross world 协调]]
> 
> 换句话说，world switch & nested memory switch 这两个工作, L0, L1 分别有其擅长的部分，但是目前缺少L0，L1的协调，让其各自负责其擅长部分


> [!PDF|important] [[osdi2026-janus-paper.pdf#page=6&selection=415,17,416,43&color=important|📖 JANUS 额外采用三个技术优化内存虚拟化 (其中两个为新技术，用于减少和 L0的 world switch)]]
> * multi-level page tables: `JANUS` 不track Guest的GPT，但是需要额外的机制保护switcher，简单来说，就是创建shadow root page，并在shadow root page中，搞一个 PUD entry 来固定映射switcher。当 L2 要更新PGD时，需要执行一个额外的hypercall来同步L1 shadow root page，此时L1 会check L2 有没有修改 switcher映射。
> * VMFUNC -- EPTP Switching: 因为 `L1`和 `L2` 有不同的EPT映射，所以在`L2` `L1`  切换过程中，需要切换EPTP, 而这个行为可以通过 `VMFUNC EPTP Switching` 硬件feature优化。从而避免trap L0。
> * Virtualization Exception:  如果L2 触发EPT violation，`VE` hw feature 可以预先将该event 首先通过`#VE` 事件的方式，直接注入 `L1`，这时`L1` 会分配相应的根据 为 GPA<sub>L2</sub>分配 GPA<sub>L1</sub>, 并通过 `hypercall` 的方式通知`L0` 更新EPT<sub>02</sub>, 减少一次不必要的world switch。(如果没有`VE`, L2 触发 EPT violation后，trap `L0`, `L0` 会将ept violation注入`L1`,  这个行为和直接触发 `VE`等效，但是多了一次world switch)

> [!PDF|important] [[osdi2026-janus-paper.pdf#page=8&selection=136,48,183,6&color=important|📖JANUS 做到的两个关键贡献]]
> 1. 所有L2的事件 -- (syscall, pagefault, interrupt) 全部交给L1 直接处理(和PVM一样)
> 2. EPT<sub>02</sub> 管理绕过任何中间的L1页表(相当于不用影子页表track了) 。并且每次 EPT<sub>02</sub>的更新只需要一次道 L0的world switch

> [!PDF|important] [[osdi2026-janus-paper.pdf#page=8&selection=455,16,486,8&color=important|📖 switcher 不仅要通过 切换CR3 切换 GPTL2 GPTL1, 同时要通过切换 EPTP切换EPT02, EPT01]]
> > Consequently, the world switches involve the switching of GPTL2 and GPTL1 on CR3, and the switching of EPT0→2 and EPT0→1 on EPTP.
>

> [!PDF|translate] [[osdi2026-janus-paper.pdf#page=8&selection=486,9,519,39&color=translate|📖 JANUS switcher 设计的两个精巧的点]]
> 1. 只有shadow root page table 需要同步
> 2. EPT切换不会trap L0,并且能很好处理 访问 switcher带来 EPT faults.

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO