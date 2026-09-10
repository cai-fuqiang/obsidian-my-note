---
modified: 2026-09-10T11:10:07+08:00
created: 2026-09-04T15:47:22+08:00
share_link: https://share.note.sx/cu8ajq1r#CQiNG3WHpmKsph4Bq2rbOg
share_updated: 2026-09-10T11:04:08+08:00
---
# 论文原文

 > [!PDF|important] [[11-archive/01-completed-project/调研PVM-new/pdf/sosp2023-pvm-paper.pdf#page=11&selection=331,0,338,35&color=important|📖 论文原文]]
 >> We used a micro-benchmark to repeatedly allocate and release 1MB of memory in a guest’s virtual address space and access the allocated data at page granularity. This process continued until the accessed data reached 4GB. This benchmark caused frequent updates to the guest page table and thus stress-tested memory virtualization. To examine scalability, we adjusted the number of benchmark processes from 1 to 32 within a single container. 
> 
> 单线程 动作:
> * 重复申请释放1MB memory in Guest, 直到访问的内存总量达到4GB.
>
> 多线程动作 
> * 在==单个==容器中启动1-32 benchmark processes
 
 
# benchmark测试

测试程序: [[06c10-trigger-pf程序]]

测试结果:

| 测试项目                                       | 时间                                             |
| ------------------------------------------ | ---------------------------------------------- |
| bare-1                                     | 1.14                                           |
| kvm_ept-1                                  | 1.37                                           |
| kvm_nst-1                                  | <mark style="background:#affad1">1.2</mark>    |
| kvm_pvm-1                                  | <mark style="background:#ff4d4f">6.4</mark>    |
| kvm_pvm-1(mmap with MAP_POPULATE)          | <mark style="background:#fdbfff">1.995 </mark> |
| bare-16                                    | 1.356                                          |
| kvm_ept-16                                 | 3.861                                          |
| kvm_nst-16                                 | <mark style="background:#affad1">3.274</mark>  |
| kvm_pvm-16                                 | <mark style="background:#ff4d4f">25.443</mark> |
| kvm_ept-16(openeuler 6.6)                  | <mark style="background:#b1ffff">2.643</mark>  |
| kvm_ept-16(L1 pvm kernel with pv_spinlock) | <mark style="background:#affad1">3.6</mark>    |
| kvm_pvm-16(mmap with MAP_POPULATE)         | <mark style="background:#fdbfff">9.827 </mark> |
这感觉已经说明问题了, `kvm-nst` 居然比`kvm-ept` 性能还要好，`kvm-pvm`性能最差。

> [!summary] 可以发现在L1 中测试该trigger pf程序耗时较长...

我们接下来用 perf 抓取下。
#  使用perf抓取热点

 > [!note] 测试程序使用16 threads

* L1

```
+   99.60%     0.00%  pf_trigger   pf_trigger         [.] main
+   63.65%     5.41%  pf_trigger   pf_trigger         [.] benchmark_worker
+   57.50%     8.17%  pf_trigger   [kernel.kallsyms]  [k] asm_exc_page_fault
+   48.76%     0.03%  pf_trigger   [kernel.kallsyms]  [k] folio_lruvec_lock_irqsave
+   48.76%     0.53%  pf_trigger   [kernel.kallsyms]  [k] _raw_spin_lock_irqsave
+   48.22%    48.22%  pf_trigger   [kernel.kallsyms]  [k] queued_spin_lock_slowpath
+   47.96%     0.30%  pf_trigger   [kernel.kallsyms]  [k] exc_page_fault
```

* L0
```
+   49.69%     0.00%  pf_trigger       libc.so.6                [.] 0x00007f163b85a9d0
+   49.69%     0.00%  pf_trigger       pf_trigger               [.] main              
+   48.32%     0.00%  swapper          [kernel.kallsyms]        [k] common_startup_64 
+   48.32%     0.00%  swapper          [kernel.kallsyms]        [k] start_secondary   
+   48.32%     0.00%  swapper          [kernel.kallsyms]        [k] cpu_startup_entry 
+   48.32%     0.00%  swapper          [kernel.kallsyms]        [k] do_idle           
+   47.71%     0.00%  swapper          [kernel.kallsyms]        [k] cpuidle_idle_call 
+   47.14%     0.00%  swapper          [kernel.kallsyms]        [k] cpuidle_enter     
+   47.14%     0.01%  swapper          [kernel.kallsyms]        [k] cpuidle_enter_stat
+   47.07%    47.07%  swapper          [kernel.kallsyms]        [k] intel_idle        
+   40.84%     6.59%  pf_trigger       pf_trigger               [.] benchmark_worker  
+   32.78%     0.00%  pf_trigger       [kernel.kallsyms]        [k] asm_exc_page_fault
+   27.43%     1.83%  pf_trigger       [kernel.kallsyms]        [k] exc_page_fault    
+   26.22%     0.00%  pf_trigger       [kernel.kallsyms]        [k] do_user_addr_fault
+   23.17%     1.24%  pf_trigger       [kernel.kallsyms]        [k] handle_mm_fault   
+   21.93%     1.36%  pf_trigger       [kernel.kallsyms]        [k] __handle_mm_fault 
+   20.56%     1.24%  pf_trigger       [kernel.kallsyms]        [k] do_anonymous_page 
+    9.42%     0.00%  pf_trigger       [kernel.kallsyms]        [k] alloc_anon_folio  
+    8.85%     0.00%  pf_trigger       libc.so.6                [.] __munmap          
```

> [!summary] 可以发现 L1 运行 pf_trigger 程序，主要耗时在queue spinlock， 但是从裸机测并没有该现象。热点还是比较分散的

# 测试 spinlock性能
## 使用bpftrace抓取spinlock执行次数和时间

> [!warning] 注意和spinlock 本身执行时间相比，bpftrace kprobe hook 占比时间是可能是比较高的，这个我还没有测试。

程序 见: [[06c11-spinlock-track-bpf]]

结果:

````ad-note
collapse: true
title: L0, L1执行结果展开
![[06c11-spinlock-track-bpf-result#L0|L0]]
![[06c11-spinlock-track-bpf-result#L1|L1]]
````

`L1` 比`L0` 触发spinlock的次数多，并且每次执行的时间也长。

> [!notion] 触发次数不同, 并且而单次spinlock占用时间长，可能是竞争（争抢）比较大导致. （说明L1 对比L0 有更多次走了 slow path)

>[!question]  会不会是虚拟化损耗导致？

使用perf工具再次打开L1 的 perf record 输出文件，观察下spinlock 中的热点指令: `__pv_queued_spin_lock_slowpath`
```
       │     ↓ jne        2ec
  1.32 │2b5:   pause
 73.23 │       sub        $0x1,%eax
       │     ↓ je         2ec  
  5.91 │2bc:   mov        0x8(%r13),%edx
  6.06 │       test       %edx,%edx
```


> [!question] 会不会是guest 中 pause性能差给spinlock带来高延迟导致的呢？
> > [!todo] 我们接下里来[[06c01-PVM-PF-PERF-README#测试pause性能| 测试下pause性能]]
## 测试pause性能

> [!bug] 请注意，测试pause性能意义可能并不大 -- 因为pause指令本身本身就是让当前thread暂停一会（让渡给其他thread执行）。 **除非pause==频繁造成vm-exit==，或者==指令本身周期很长==，给spinlock的高延迟。否则pause指令性能本身无需关注**。
### pause on userspace
可以发现大部分卡在pause， 我们编写一个程序来测试pause.
```cpp
int main()
{
        int i, j,k;
        for (i = 0 ;i < 1024;i++)
        for (j = 0 ;j < 1024;j++)
        for (k = 0 ;k < 500;k++)
                __asm__("pause");
}
```

用该程序在L1 L0中执行，并关注执行时间.

| -     | 单条pause执行时间 | 执行次数      | 执行总时间  |
| ----- | ----------- | --------- | ------ |
| L1/L1 | 7.9         | 524288000 | 4.17 s |
| L0    | 7.8         | 524288000 | 4.13 s |

可见执行时间类似.

> [!faq] 为什么会这样呢？难到执行pause不会vm-exit，让kvm模拟么?
> intel cpu 支持ple feature, 根据 [[intel_spec-ple|对intel sdm ple 调研]] 来看，ple feature 只作用于`CPL == 0`，而所以当处于用户态时，仅判断 `pause exiting`, 此时该值为0，所以并不会vm-exit。

> [!todo] 我们来测试下内核态`pause`的性能

### pause on kernel space
[[06c12-kmod-pause-benchmark]] 使用pause_test测试

单条pause耗时时间如下:

| -   | 单条pause执行时间 | 执行次数      | 执行总时间   |
| --- | ----------- | --------- | ------- |
| L1  | 24ns        | 134217728 | 1049 ms |
| L0  | 7ns         | 134217728 | 3273 ms |
可以发现L1比L0的执行时间高出3倍左右。我们再来关注下运行L1是，host vm-exit的情况:

```python unwrap:true

Analyze events for all VMs, VCPU 1:

                                 VM-EXIT    Samples  Samples%     Time%    Min Time    Max Time         Avg time

                      EXTERNAL_INTERRUPT        370    96.35%    98.40%      0.00us     12.28us      3.23us ( +-   1.39% )
                       PAUSE_INSTRUCTION         14     3.65%     1.60%      0.00us      2.76us      1.39us ( +-  10.57% )

Total Samples:384, Total events handled time:1216.30us.
Hygon C86 7390 32-core Processor

```

> [!summary] 可以发现，因为handle event 所消耗的时间占比非常小，大概是 $\frac{1}{300}$, **所以，还是==guest中执行pause指令周期本身比较长==导致**

> [!notion] 为什么guest kernel 执行pause指令比较长呢 ，而用户态并无太大差距呢？
> 个人猜测，intel 为实现ple的逻辑，在CPL == 0 时，加入了一些额外的判断逻辑导致pause指令执行比较长。（当然也可以是其他原因)

> [!question]  L1 比L0 高三倍左右的pause指令周期会不会对spinlock的性能造成影响呢 ?

> [!todo] 那我们需要测试下spinlock性能

## my spinlock in usespace

上面我们有用户态执行spinlock的执行周期, 所以我们可以先简单写一个用户态程序，简单实现一个spinlock，并测试每次spinlock的执行时间。从而评估pause指令的执行周期所带来的影响。

[[06c13-userspace-spinlock | userspace spinlock 测试程序]]

结果如下:

| Lx  | 线程数量 | per spinlock cost (us) -- tas | per spinlock cost(us) -- mcs |
| --- | ---- | ----------------------------- | ---------------------------- |
| L0  | 2    | 53                            | 170                          |
| L0  | 4    | 110                           | 328                          |
| L0  | 8    | 207                           | 378                          |
| L0  | 16   | 418                           | 365                          |
| L0  | 32   | 608                           | 388                          |
| L1  | 2    | 59                            | 186                          |
| L1  | 4    | 104                           | 337                          |
| L1  | 8    | 209                           | 360                          |
| L1  | 16   | 414                           | 349                          |
| L1  | 32   | 596                           | 471                          |
可以看到，在多线程时（4线程+)，获取自旋锁的延迟都上百了，个人认为因为pause带来的延迟差别不大。

> [!question] 那内核侧自旋锁 性能如何呢?


## kernel spinlock benchmark

[[06c14-kernel-spinlock-benchmark| benchmark程序]]

测试结果如下:

| Lx  | 线程数量 | host oe 2403 | guest oe 2403  | host pvm | guest pvm |
| --- | ---- | ------------ | -------------- | -------- | --------- |
| L0  | 2    | 104          | 254            | 101      | 418       |
| L0  | 4    | 1085         | 725            | 1040     | 950       |
| L0  | 8    | 1706         | 1440           | 1688     | 1888      |
| L0  | 16   | 2900         | 2968           | 3203     | 3916      |
| L0  | 32   | 5400         | 不稳定(2246-5679) | 5526     | 8097      |

从数据上来看，guest oe 2403 性能出色，但是总体和guest差别不大(可能有一定的误差），但是Guest PVM 明显存在一些差距.

但是从vm-exit来看，两者并不太大差距。

pvm guest
```
Analyze events for all VMs, VCPU 1:

                                 VM-EXIT    Samples  Samples%     Time%    Min Time    Max Time         Avg time

                                     HLT       8859    43.40%    98.98%      0.54us    676.59us    312.21us ( +-   0.52% )
                                  VMCALL       6113    29.95%     0.49%      1.12us     16.41us      2.22us ( +-   0.42% )
                               MSR_WRITE       3000    14.70%     0.21%      1.13us      9.84us      1.96us ( +-   0.31% )
                       PAUSE_INSTRUCTION       1919     9.40%     0.25%      1.07us     38.71us      3.71us ( +-   1.43% )
                      EXTERNAL_INTERRUPT        340     1.67%     0.06%      1.09us    106.87us      4.74us ( +-   8.45% )
                        PREEMPTION_TIMER        182     0.89%     0.01%      0.72us      2.44us      1.12us ( +-   1.24% )
```

guest oe 2403

```
Analyze events for all VMs, VCPU 1:

                                 VM-EXIT    Samples  Samples%     Time%    Min Time    Max Time         Avg time

                                     HLT       8966    43.79%    99.01%      0.56us    650.47us    309.53us ( +-   0.50% )
                                  VMCALL       6222    30.39%     0.49%      1.22us     37.56us      2.22us ( +-   0.46% )
                               MSR_WRITE       3001    14.66%     0.21%      1.10us     38.98us      1.98us ( +-   0.65% )
                       PAUSE_INSTRUCTION       1814     8.86%     0.24%      1.01us     34.29us      3.75us ( +-   1.59% )
                      EXTERNAL_INTERRUPT        283     1.38%     0.04%      1.38us     12.58us      3.91us ( +-   3.07% )
                        PREEMPTION_TIMER        190     0.93%     0.01%      0.74us      1.42us      1.08us ( +-   0.73% )
```


### 阶段性总结

> [!summary] 所以，个人认为, Guest/Host 处理spinlock的性能差距不足以造成, 看起来还是在虚拟机场景下，**==锁争抢更激烈==导致**


# 进一步分析锁的争抢

L1的perf显示 争抢锁的 函数为 `folio_lruvec_lock_irqsave` , 代码:
```cpp
struct lruvec *folio_lruvec_lock_irqsave(struct folio *folio,
		unsigned long *flags)
{
	struct lruvec *lruvec = folio_lruvec(folio);

	spin_lock_irqsave(&lruvec->lru_lock, *flags);
	lruvec_memcg_debug(lruvec, folio);

	return lruvec;
}
```

其中 `folio_lruvec()` 会根据当前页所在的`memcg`或者是`pgdat` 获取`lruvec`。而无论是 `memcg` ,还是 `pgdat`，`lruvec`都是 per node的.

```sh
mem_cgroup_lruvec
=> if (mem_cgroup_disable()) 
   => lruvec = &pgdat->__lruvec
   => goto out
=> mz = memcg->nodeinfo[pgdat->node_id]
   => lruvec = $mz->lruvec
```

> [!danger] 而物理机的硬件配置为 2 NUMA , 虚拟机配置为1 NUMA。

下面，我们测试下物理机和虚拟机 && numa 数量的性能对比(依旧使用 [[06c10-trigger-pf程序 | trigger-pf]] 以参数 `-n 16` 测试)。

# L1 提升numa 后，进一步测试pf

| 测试case                | 执行时间      |
| --------------------- | --------- |
| host-1numa            | 2.634     |
| host-2numa            | 1.348     |
| L1-pvmkernel-1numa    | 3.217     |
| L1-pvmkernel-2numa    | 1.5~1.6   |
| L1-pvmkernel-4numa    | 1.369     |
| L1-oe2403kernel-1numa | 2.574     |
| L1-oe2403kernel-2numa | 1.5~1.833 |
| L1-oe2403kernel-4numa | 1.461     |
> [!summary]  可以看到无论是`oe2403kernel` 还是 `pvmkernel` 作为L1底座，在2numa的情况下,  能达到不错的性能提升。在提升到4numa时，性能提升幅度不大


# PVM L2 性能差原因分析

## 热点抓取以及初步代码分析

当我们在 `PVM L2` 执行 [[06c10-trigger-pf程序|trigger-pf]] 程序时，在L1抓取热点:
```
+   74.70%     0.00%  CPU 9/KVM  libc.so.6          [.] ioctl
+   67.28%     0.00%  CPU 9/KVM  [kernel.kallsyms]  [k] entry_SYSCALL_64
+   67.28%     0.00%  CPU 9/KVM  [kernel.kallsyms]  [k] do_syscall_64
+   67.28%     0.00%  CPU 9/KVM  [kernel.kallsyms]  [k] __x64_sys_ioctl
+   67.28%     0.00%  CPU 9/KVM  [kvm]              [k] kvm_vcpu_ioctl
+   67.28%     0.00%  CPU 9/KVM  [kvm]              [k] kvm_arch_vcpu_ioctl_run
+   67.28%     0.38%  CPU 9/KVM  [kvm]              [k] vcpu_run
+   66.52%     4.61%  CPU 9/KVM  [kvm]              [k] vcpu_enter_guest.constprop.0
+   53.88%     0.29%  CPU 9/KVM  [kvm]              [k] kvm_mmu_page_fault
+   53.59%     0.35%  CPU 9/KVM  [kvm]              [k] kvm_mmu_do_page_fault
+   53.24%     0.00%  CPU 9/KVM  [kvm]              [k] paging64_page_fault
+   38.33%    11.38%  CPU 9/KVM  [kernel.kallsyms]  [k] queued_write_lock_slowpath
+   25.54%    20.00%  CPU 9/KVM  [kernel.kallsyms]  [k] __pv_queued_spin_lock_slowpath
+    6.68%     1.84%  CPU 9/KVM  [kvm]              [k] paging64_fetch
+    5.06%     0.33%  CPU 9/KVM  [kernel.kallsyms]  [k] sysvec_apic_timer_interrupt
+    5.06%     0.00%  CPU 9/KVM  [kernel.kallsyms]  [k] asm_sysvec_apic_timer_interrupt
```

可以发现，PF占很大比例，另外,  关于锁的争抢也很严重。

争抢锁的代码:
```sh
FNAME(page_fault)
# 遍历guest页表
=> FNAME(walk_addr)
# 分配物理页
=> kvm_faultin_pfn()
=> write_lock(&vcpu->kvm->mmu_lock)
# 补全影子页表
=> r = FNAME(fetch)(vcpu, fault, &walker);
=> write_unlock(&vcpu->kvm->mmu_lock)
```

fetch 的全程是加自旋锁。（write lock）


## PF 究竟触发了多少次

编写下面bpftrace脚本，来抓取 PF 的触发数量，以及`free root`的数量以及堆栈

> [!note] 为了方便起见，我们以 单线程的方式测试
> 具体参数:
> ```
> ./pf_trigger -n 1 -t $((1024*1024*1024*4))
> ```

```cpp
kprobe:kvm_mmu_free_roots
{
	@stack[kstack()] = count();
}

kprobe:paging64_page_fault
{
	@page_fault_count = count();
}
```

打印如下:
```
@page_fault_count: 2117345
@stack[
    kvm_mmu_free_roots+1
    kvm_set_cr3+305
    handle_exit_syscall+312
    vcpu_enter_guest.constprop.0+1458
    vcpu_run+47
    kvm_arch_vcpu_ioctl_run+314
    kvm_vcpu_ioctl+725
    __x64_sys_ioctl+141
    do_syscall_64+91
    entry_SYSCALL_64_after_hwframe+118
]: 4099
@stack[
    kvm_mmu_free_roots+1
    handle_synthetic_instruction_return_user+43
    vcpu_enter_guest.constprop.0+1458
    vcpu_run+47
    kvm_arch_vcpu_ioctl_run+314
    kvm_vcpu_ioctl+725
    __x64_sys_ioctl+141
    do_syscall_64+91
    entry_SYSCALL_64_after_hwframe+118
]: 4117
```

有两个有意思的现象:
* PF 数量为`2117345` , 该数值是以页为单位，转换成字节数约为`8GB`。那也就是说，每个页产生了两次page fault? 
 * `handle_exit_syscall/kvm_set_cr3` 这个路径是其实是flush tlb的路径（这里不展开），次数为`4099`次。

> [!todo] 我们先关注第二个现象：为什么free root的数量是4099次

这个次数很像是mmap的数量(当前程序中每次mmap的大小为1M), 访问的地址区域为4GB。所以会有4096次的`mmap/umap`

如果我们将

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/kernel_test/master/pf_trigger/pf_trigger.c"
LINES: "11-13"
TITLE: "pf_trigger"
FONT_SIZE: 12
COMMENTS:
```

将11行修改为 `(1024* 1024 * 2)` 也就是单次mmap大小为2M，该次数会减少一半。

> [!notion] 那也就是说，Guest 每次unmap 都会flush all tlb，此时L1 PVM 会 销毁该 root。（释放该root全部的影子页表）

***

> [!todo] 每访问一个页真的要造成两次PF?

编写PF程序，打印具体的PF信息
```
kprobe:kvm_handle_page_fault
{
        @cr2_addr_error[arg2, arg1 ] = count();
}
```

打印如下
```
@cr2_addr_error[-92908732035068, 11]: 108
@cr2_addr_error[-92908731679064, 2]: 440
@cr2_addr_error[-92908731646296, 2]: 441
@cr2_addr_error[-92908731613528, 2]: 686
@cr2_addr_error[-102250284069092, 0]: 1288
@cr2_addr_error[-102250116050944, 3]: 4097
@cr2_addr_error[140537656766464, 6]: 8192
@cr2_addr_error[140537656659968, 6]: 8192
@cr2_addr_error[140537656999936, 6]: 8192
@cr2_addr_error[140537656520704, 6]: 8192
@cr2_addr_error[140537656553472, 6]: 8192
@cr2_addr_error[140537657040896, 6]: 8192
@cr2_addr_error[140537657090048, 6]: 8192
```

可以发现很多用户态的虚拟地址触发了`8192`次page fault，`error_code`为6, 说明是因为`not present` 触发的。

而第6行，也比较有意思。首先是一个内核地址，另外 error_code 为3 。表示是一个`WP`的异常。我目前怀疑是每次umap时，都会clear PDE。而PDE不是lastlevel 所以没有unsync优化，导致每次都触发`WP`。

> [!todo] 进一步确认每次地址访问触发了两次连续的`#PF` 

我们在程序中打开第46行注释。增加对每次访问页的打印。

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/kernel_test/master/pf_trigger/pf_trigger.c"
LINES: "44-48"
TITLE: "pf_trigger"
FONT_SIZE: 12
COMMENTS:
```

执行下面bpftrace 脚本:
```
kprobe:kvm_handle_page_fault
{
	if (arg1 == 6 && ((arg2 & 0x7f0000000000) == 0x7f0000000000)) {
		printf("addr(%lx) error_code (%lu) \n", arg2, arg1);
	}
}

```

bpftrace 脚本打印:
```
addr(7f8750690000) error_code (6)
addr(7f8750690000) error_code (6)
addr(7f8750691000) error_code (6)
addr(7f8750691000) error_code (6)
addr(7f8750692000) error_code (6)
addr(7f8750692000) error_code (6)
```

trigger-pf程序打印:
```
the addr is 7f8750690000
the addr is 7f8750691000
the addr is 7f8750692000
```

可以发现，每访问一个地址都会触发两次`#PF`。

> [!faq] 为什么每次访问一个地址会有两次的`#PF` 触发到 `VMM` ?
> 触发流程如下:
> 1. Guest MMAP    增加虚拟地址空间，但是未建立页表映射
> 2. Guest user 访问某个地址触发`#PF`到 `VMM`
> 3. VMM 发现Guest并未补全页表映射，注入`#PF` 到Guest
> 4. Guest kernel 建立该地址的页表映射, 返回Guest User
> 5. Guest User 访问该地址, 由于影子页表没有补全，触发`#PF` 到 `VMM`
> 6. VMM 补全影子页表

> [!todo] 我们验证上面这个流程

我们首先修改 L1 内核代码中的 [[06c15-trace_kvm_inj_exception-diff|trace_kvm_inj_exception]], 增加对CR2 寄存器的打印。然后执行下面 bpftrace:
```
addr(7f3175532000) error_code (6)
inj exception vector (14) error_code(6) cr2(7f3175532000)
addr(7f3175532000) error_code (6)
addr(7f3175533000) error_code (6)
inj exception vector (14) error_code(6) cr2(7f3175533000)
addr(7f3175533000) error_code (6)
```
可以发现和我们上面推测的流程一致。
## 进一步思考

> [!note] 上面描述的场景是，对于Guest 而言，其每次收到 `#PF` 仅仅建立触发`#PF` 所在页的页表映射。对于一段地址区间，访问每个页都会触发 `#PF`

> [!faq] PVM在该场景下有没有优化空间?
> 没有。首先 `#PF` 注入肯定是要有的，另外，当注入`#PF` 时，Guest 并未在 `GPT` 中建立该页的地址映射关系，所以Guest 只能等其建立完页表映射后，再次访问该地址触发 `#PF` trap 到VMM， 然后VMM 参考GPT的映射，建立SPT。

> [!summary] 所以两次的`#PF` 均无法省略。

> [!question]  如果我们访问该地址之前, 先将页表映射准备好，是不是可以利用影子页表 pre-fault机制做一些优化?

> [!note] 关于pre-fault具体原理可以参考, [[10-spt-pre_fault可以通过预填充spte减少因PF 造成的vm-exit|pre-fault 减少vm-exit原理]]

为了构造pre-fault的场景，我们需要在访问具体页之前，先建立好页表，为此，我们可以在调用`mmap()`时，增加`MAP_POPULATE` prop flags, 该参数会使`mmap()` 调用时就建立好页表映射。我们修改后，仍然使用上面bpftrace程序测试。

经测试，不仅不再有注入`#PF` 的事件，`pre-fault` 似乎也生效了。例如第`3-4`行， 在`7f23155b0000` va触发`#PF`后，下次 触发 `#PF` 的地址为 `7f23155b8000` , 也就是 pre-fault了7个页。
```
addr(7f23155ae000) error_code (6)
addr(7f23155af000) error_code (6)
addr(7f23155b0000) error_code (6)
addr(7f23155b8000) error_code (6)
addr(7f23155c0000) error_code (6)
addr(7f23155c8000) error_code (6)
addr(7f23155d0000) error_code (6)
addr(7f23155d8000) error_code (6)
addr(7f23155e0000) error_code (6)
addr(7f23155e8000) error_code (6)
addr(7f23155f0000) error_code (6)
addr(7f23155f8000) error_code (6)
addr(7f2315600000) error_code (6)
addr(7f2315608000) error_code (6)
```

> [!success] 我们用该程序，再次测试下:
> * 单线程, 性能提升至 `1.9xx` s!
> * 16线程, 性能提升至`9.xxx` s !
> > [!warning] 不过性能仍弱于 嵌套虚拟化。

# TODO

* [ ] 🔺 分析嵌套虚拟化在什么场景下性能比较差
* [ ] 🔼 PVM 在触发 `#PF` 时, 争抢 `kvm->mmu_lock` 这个能否优化?
* [ ] 🔽  pvm kernel bpftrace 对kprobe的支持不好