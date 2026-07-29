---
data: 2026-07-28
问题分类: softlockup
是否定位成功: false
目前结论: CPU 2 在等待CPU 0 csd unlock, 但是触发softlockup 到panic这段期间，发现CSD已经unlock, 非常奇怪
is_issue: true
instance: i-23m7r699sd
---
# 堆栈

问题现象 CPU1 softlockup:

```
[40780.038333] CPU: 1 PID: 62 Comm: kswapd0 Kdump: loaded Not tainted 6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64 #1
[40780.038699] watchdog: BUG: soft lockup - CPU#2 stuck for 22s! [Reporter:24484]
[40780.064525] Hardware name: JD JCloud Iaas Jvirt, BIOS unknown 2/2/2022
[40780.064539] pc 900000000034eaa0 ra 900000000034ea74 tp 9000000101b28000 sp 9000000101b2b670
[40780.064544] a0 0000000000000000 a1 0000000000000000 a2 0000000000000000 a3 0000000000000000
[40780.064546] a4 9000000100238398 a5 9000000000641274 a6 0000000000000002 a7 0000000000000001
[40780.064547] t0 0000000000000001 t1 900000000802ff40 t2 0000000000000000 t3 90000001064f1308
[40780.064550] t4 90000001064f1300 t5 00000000000003ff t6 000000000000d2f3 t7 0000800000000000
[40780.064551] t8 ffff800000000000 u0 90000000002222e8 s9 90000000080eff40 s0 90000000025b49a0
[40780.064553] s1 900000000806ba80 s2 90000000025b9180 s3 00000000000000b4 s4 0000000000000001
[40780.064556] s5 9000000000233f00 s6 9000000003474000 s7 90000000025b49a0 s8 9000000101b2b800
[40780.064559]    ra: 900000000034ea74 smp_call_function_many_cond+0x3f4/0x598
[40780.064579]   ERA: 900000000034eaa0 smp_call_function_many_cond+0x420/0x598
[40780.064582]  CRMD: 000000b0 (PLV0 -IE -DA +PG DACF=CC DACM=CC -WE)
[40780.064593]  PRMD: 00000004 (PPLV0 +PIE -PWE)
[40780.064596]  EUEN: 00000000 (-FPE -SXE -ASXE -BTE)
[40780.064601]  ECFG: 00071c3d (LIE=0,2-5,10-12 VS=7)
[40780.064608] ESTAT: 00000818 [INT] (IS=3-4,11 ECode=0 EsubCode=0)
[40780.064613]  PRID: 0014d011 (Loongson-64bit, Loongson-3C6000/D)
[40780.064620] CPU: 1 PID: 62 Comm: kswapd0 Kdump: loaded Not tainted 6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64 #1
[40780.064624] Hardware name: JD JCloud Iaas Jvirt, BIOS unknown 2/2/2022
[40780.064626] Stack : 00000000000000b0 0000000000000000 90000000002248d4 9000000101b28000
[40780.064632]         90000001003b7be0 90000001003b7be8 0000000000000000 90000001003b7d28
[40780.064636]         90000001003b7d20 90000001003b7d20 9000000007662dc8 6572617764726148
[40780.064640]         203a656d616e2065 90000001003b7be8 bd99d81b17429998 9000000100a0a440
[40780.064644]         80000000ffff8760 90000000034b6e40 00000000ffff8760 0000000000000020
[40780.064648]         0000000000000030 000000000000002d 0000000006928000 0000000000000000
[40780.064652]         0000000000000000 0000000000000000 9000000001b04180 90000000023b5000
[40780.064656]         9000000101b2b530 9000000008043e78 90000000023b5000 90000001003b7e00
[40780.064659]         9000000008043680 0000000000000000 90000000002248ec 000055558ebab958
[40780.064663]         00000000000000b0 0000000000000004 0000000000000000 0000000000071c3d
[40780.064667]         ...
[40780.064669] Call Trace:
[40780.064674] [<90000000002248ec>] show_stack+0x64/0x188
[40780.064687] [<90000000015cffac>] dump_stack_lvl+0x5c/0x88
[40780.064700] [<900000000038fb44>] watchdog_timer_fn+0x22c/0x2a0
[40780.064710] [<9000000000331014>] __run_hrtimer+0x94/0x288
[40780.064719] [<90000000003312d0>] __hrtimer_run_queues+0xc8/0x168
[40780.064723] [<9000000000331b8c>] hrtimer_interrupt+0x13c/0x388
[40780.064727] [<9000000000228104>] constant_timer_interrupt+0x34/0x48
[40780.064733] [<90000000002e95f0>] __handle_irq_event_percpu+0x70/0x228
[40780.064746] [<90000000002e97c4>] handle_irq_event_percpu+0x1c/0x80
[40780.064751] [<90000000002f1578>] handle_percpu_irq+0x58/0x98
[40780.064763] [<90000000002e8c8c>] handle_irq_desc+0x44/0x60
[40780.064769] [<9000000000d380ec>] handle_cpu_irq+0x6c/0xa8
[40780.064782] [<90000000015d02dc>] handle_loongarch_irq+0x2c/0x48
[40780.064786] [<90000000015d0390>] do_vint+0x98/0x100
[40780.064789] [<900000000034eaa0>] smp_call_function_many_cond+0x420/0x598
[40780.064794] [<900000000034ec80>] on_each_cpu_cond_mask+0x20/0x30
[40780.064798] [<9000000000233e34>] flush_tlb_page+0x7c/0x148
[40780.064806] [<90000000005317a0>] ptep_clear_flush+0x78/0x90
[40780.064817] [<9000000000536654>] try_to_migrate_one+0x584/0x9b8
[40780.064824] [<90000000005338b0>] rmap_walk_anon+0x128/0x350
[40780.064828] [<9000000000536d4c>] try_to_migrate+0x9c/0x180
[40780.064834] [<90000000005a81e0>] split_huge_page_to_list_to_order+0x4b0/0x8f8
[40780.064845] [<90000000005a8878>] deferred_split_scan+0x250/0x3b0
[40780.064849] [<90000000004db614>] do_shrink_slab+0x13c/0x3e0
[40780.064864] [<90000000004dc078>] shrink_slab_memcg+0x250/0x340
[40780.064868] [<90000000004d7f04>] shrink_node_memcgs+0x204/0x268
[40780.064874] [<90000000004d8010>] shrink_node+0xa8/0x400
[40780.064877] [<90000000004d86b0>] balance_pgdat+0x348/0x6e0
[40780.064882] [<90000000004d8b80>] kswapd+0x138/0x288
[40780.064886] [<9000000000284790>] kthread+0xf8/0x108
[40780.064897] [<90000000015d1348>] ret_from_kernel_thread+0x28/0x60
[40780.064902] [<90000000002220b8>] ret_from_kernel_thread_asm+0xc/0xb4
```

# 初步分析

## softlockup 触发位置

查看 `smp_call_function_many_cond()` 具体的代码位置:
```sh
/usr/src/debug/kernel-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/linux-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/kernel/smp.c: 320
0x900000000034ea90 <smp_call_function_many_cond+1032>:  ldptr.w         $t0, $t1, 8
0x900000000034ea94 <smp_call_function_many_cond+1036>:  andi            $t0, $t0, 0x1
0x900000000034ea98 <smp_call_function_many_cond+1040>:  beqz            $t0, 20 # 0x900000000034eaac <smp_call_function_many_cond+1060>
0x900000000034ea9c <smp_call_function_many_cond+1044>:  nop
0x900000000034eaa0 <smp_call_function_many_cond+1048>:  ldptr.w         $t0, $t1, 8
0x900000000034eaa4 <smp_call_function_many_cond+1052>:  andi            $t0, $t0, 0x1
0x900000000034eaa8 <smp_call_function_many_cond+1056>:  bnez            $t0, -8 # 0x900000000034eaa0 <smp_call_function_many_cond+1048>
```
C代码, 等 `csd lock`:
```cpp
static __always_inline void csd_lock_wait(struct __call_single_data *csd)
{
	smp_cond_load_acquire(&csd->node.u_flags, !(VAL & CSD_FLAG_LOCK));
}
```

而在`smp_call_function_many_cond()` 执行`csd_lock_wait()`有两个位置:
```sh
smp_call_function_many_cond
...
=> if (run_remote)
   ## 找到该cpu的cfd，并且将cpumask 除了当前cpu全部掷位
   => cfd = this_cpu_ptr(&cfd_data)
   => cpumask_and(cfd->cpumask, mask, cpu_online_mask)
   => __cpumask_clear_cpu(this_cpu, cfd->cpumask)
   ## 先clear
   => cpumask_clear(cfd->cpumask_ipi)
   => for_each_cpu(cpu, cfd->cpumask)
      ## 找到要发送ipi的目的cpu的csd
      => call_single_data_t *csd = per_cpu_ptr(cfd->csd, cpu)
      ## 如果有其他cpu 已经lock 了csd(说明有pending的请求还未处理(async的)), 
      ## 等待其处理完
      => csd_lock(csd)
         ##
         ## !位置1
         ##
         => csd_lock_wait(csd)
         ## 等待完后，lock
         => csd->node.u_flags |= CSD_FLAG_LOCK
      => csd->func = func
      => csd->info = info
      ## 串联到 call_single_queue准备处理
      => llist_add(&csd->node.llist, &per_cpu(call_single_queue, cpu))
      ## 
      ## set cfd->cpumask_ipi
      ## !!这是个关键位置==(1)==
      ##
      => __cpumask_set_cpu(cpu, cfd->cpumask_ipi)
   ## 发送ipi
   => send_call_function_ipi_mask/single_ipi()
## 如果是显示制定wait，需要在这里等待 csd_unlock
=> if (run_remote && wait)
   => for_each_cpu(cpu, cfd->cpumask) ## 851 行左右
      => csd = per_cpu_ptr(cfd->csd, cpu)
      ##
      ## !位置2
      ##
      => csd_lock_wait()
```

怎么判断是在位置1，还是位置2呢，我们可以通过 `(1)`处的 `cfd->cpumask_ipi`判断

```
per_cpu(cfd_data, 1) = $3 = {
  csd = 0x9000000001747f40,
  cpumask = 0x900000010023a4a0,
  cpumask_ipi = 0x9000000100238390
}

crash> rd 0x9000000100238390
9000000100238390:  000000000000000d
```
也就是除了当前的CPU(CPU 1), 均发送了IPI。

> [!tip]  也可以通过反汇编来查看，下面我们会详细解释

```ad-question
究竟是在等待哪个CPU呢?
```

## 寻找等待的cpu

我们结合汇编来看
```sh
# 这里是个突破点，因为 _find_next_bit 返回的是 bit index, 其实就是cpu
# 另外 851这行也说明 csd_lock_wait()是位于第二个位置（1032 这个位置无其他代码跳转)
0x900000000034ea70 <smp_call_function_many_cond+1000>:  bl              9176408 # 0x9000000000c0efc8 <_find_next_bit>
/usr/src/debug/kernel-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/linux-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/kernel/smp.c: 851
# t0表示 nr_cpu_ids
0x900000000034ea74 <smp_call_function_many_cond+1004>:  ldptr.w         $t0, $s2, 0
# 这行汇编更像是将 a0 变为32位类似于强转int
0x900000000034ea78 <smp_call_function_many_cond+1008>:  slli.w          $a0, $a0, 0x0
# 判断 cpu >= nr_cpu_ids
0x900000000034ea7c <smp_call_function_many_cond+1012>:  bgeu            $a0, $t0, -776  # 0x900000000034e774 <smp_call_function_many_cond+236>
/usr/src/debug/kernel-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/linux-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/kernel/smp.c: 854
# 这里获取该cpu 的__per_cpu_offset 值的位置 在 __per_cpu_offset[]数组中的 offset地址偏移，也就是 cpu * sizeof(u64)
0x900000000034ea80 <smp_call_function_many_cond+1016>:  slli.d          $t0, $a0, 0x3
# s0表示__per_cpu_offset 地址, 加上t0 得到了 __per_cpu_offset[cpu]的地址
0x900000000034ea84 <smp_call_function_many_cond+1020>:  ldx.d           $t0, $s0, $t0
# s1表示cfd地址 这里实际上读取到了 cfd->csd的地址
0x900000000034ea88 <smp_call_function_many_cond+1024>:  ldptr.d         $t1, $s1, 0
# 得到该cpu的 cfd->csd的地址, 给t1
0x900000000034ea8c <smp_call_function_many_cond+1028>:  add.d           $t1, $t1, $t0
/usr/src/debug/kernel-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/linux-6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64/kernel/smp.c: 320
# 获取 csd.node.u_flags
0x900000000034ea90 <smp_call_function_many_cond+1032>:  ldptr.w         $t0, $t1, 8
# 判断是否有 CSD_FLAG_LOCK bit
0x900000000034ea94 <smp_call_function_many_cond+1036>:  andi            $t0, $t0, 0x1
# 如果是0 则跳转, 说明没有lock
0x900000000034ea98 <smp_call_function_many_cond+1040>:  beqz            $t0, 20 # 0x900000000034eaac <smp_call_function_many_cond+1060>
0x900000000034ea9c <smp_call_function_many_cond+1044>:  nop
# 如果不是0，继续load
0x900000000034eaa0 <smp_call_function_many_cond+1048>:  ldptr.w         $t0, $t1, 8
0x900000000034eaa4 <smp_call_function_many_cond+1052>:  andi            $t0, $t0, 0x1
# 如果不是0， 则继续走load
0x900000000034eaa8 <smp_call_function_many_cond+1056>:  bnez            $t0, -8 # 0x900000000034eaa0 <smp_call_function_many_cond+1048>
0x900000000034eaac <smp_call_function_many_cond+1060>:  dbar            0x15
```
触发softlockup时, ip位于`0x900000000034eaa0`, 也就是说刚执行完跳转。

| reg | 表示                                 |
| --- | ---------------------------------- |
| t1  | &csd                               |
| t0  | csd.node.u_flags & CSD_FLAG_LOCK的值 |
| a0  | 等待的cpu                             |
| s0  | `&__per_cpu_offset`                |
| s1  | cfd                                |
| s2  | `&nr_cpu_ids`                      |
获取`pt_regs`, 由于crash `bt -f`命令打印不出pt_regs， 我们在`smp_call_function_many_cond sp - sizeof(pt_regs)`, 即为`pt_regs`的地址:
```
crash> bt |grep smp
#13 [9000000101b2b670] smp_call_function_many_cond at 900000000034eaa0
crash> p *(struct pt_regs*)(0x9000000101b2b670-sizeof(struct pt_regs)) -x
$12 = {
  regs = {0x0, 0x900000000034ea74, 0x9000000101b28000, 0x9000000101b2b670, 0x0, 0x0, 0x0, 0x0, 0x9000000100238398, 0x9000000000641274, 0x2, 0x1, 0x1, 0x900000000802ff40, 0x0, 0x90000001064f1308, 0x90000001064f1300, 0x3ff, 0xd2f3, 0x800000000000, 0xffff800000000000, 0x90000000002222e8, 0x90000000080eff40, 0x90000000025b49a0, 0x900000000806ba80, 0x90000000025b9180, 0xb4, 0x1, 0x9000000000233f00, 0x9000000003474000, 0x90000000025b49a0, 0x9000000101b2b800},
  orig_a0 = 0x9000000000233f00,
  csr_era = 0x900000000034eaa0,
  csr_badvaddr = 0x0,
  csr_crmd = 0xb0,
  csr_prmd = 0x4,
  csr_euen = 0x0,
  csr_ecfg = 0x71c3d,
  csr_estat = 0x818,
  __last = 0x9000000101b2b670
}
```

通过 `pt_regs.csr_era`以及`pt_regs.regs[r3]`都可以判断 该pt_regs是正确的， 我们来补充完上面的表:

| reg | 表示                                 | alias | val                       |
| --- | ---------------------------------- | ----- | ------------------------- |
| t1  | &csd                               | r13   | 0x900000000802ff40        |
| t0  | csd.node.u_flags & CSD_FLAG_LOCK的值 | r12   | 1                         |
| a0  | 等待的cpu                             | r4    | 0                         |
| s0  | `&__per_cpu_offset`                | r23   | 0x90000000025b49a0        |
| s1  | cfd                                | r24   | 0x900000000806ba80        |
| s2  | `&nr_cpu_ids`                      | r25   | 0x90000000025b9180(值为128) |

我们验证下cfd 和csd 以及cpu的值:
```
# cfd
crash> p cfd_data |grep -E '[1]'
  [1]: 900000000806ba80
# cpu 我们按照0 来计算 csd
crash> p 0x9000000001747f40 + __per_cpu_offset[0] -x
$24 = 0x900000000802ff40
```

我们获取cpu 0 的 csd:
```
crash> call_single_data_t 0x900000000802ff40
struct call_single_data_t {
  node = {
    llist = {
      next = 0x0
    },
    {
      u_flags = 0,
      a_flags = {
        counter = 0
      }
    },
    src = 0,
    dst = 0
  },
  func = 0x9000000000233f00 <flush_tlb_page_ipi>,
  info = 0x9000000101b2b730
}
```

`u_flags`  居然是0 !, 而 在上面通过 t0 看 `u_flags`为1

```ad-danger
title: 不会这么巧, 在softlockup 处理期间，u_flags 发生了改变吧...
```

> [!note]  进一步通过`call_single_queue:0` 验证下CPU 0 是否已经处理完 CPU 2 的CSD
> ```
> crash> p call_single_queue:0
> per_cpu(call_single_queue, 0) = $26 = {
>   first = 0x9000000119a72420
> }
> crash> rd 0x9000000119a72420
> 9000000119a72420:  0000000000000000                    ........
> ```
> 目前CPU0 链上**只有一个csd，该csd 不是 `cfd:2->csd:0`**

```ad-summary
目前的结论是:
* 目前CPU 2 等待的CPU 是 **CPU0**
* 但是目前 看起来**==CPU 0 已经执行完`csd_unlock`==**
```

<!--
# 附录
我们来看下,  哪些CPU是lock的。
```
crash> p call_single_queue
PER-CPU DATA TYPE:
  struct llist_head call_single_queue;
PER-CPU ADDRESSES:
  [0]: 900000000802ba40
  [1]: 900000000806ba40
  [2]: 90000000080aba40
  [3]: 90000000080eba40
crash> rd 900000000802ba40
900000000802ba40:  9000000119a72420                     $......
crash> rd 900000000806ba40
900000000806ba40:  900000000806c160                    `.......
crash> rd 90000000080aba40
90000000080aba40:  90000000080ac160                    `.......
crash> rd 90000000080eba40
90000000080eba40:  0000000000000000                    ........
## CPU 0
crash> call_single_data_t 9000000119a72420
struct call_single_data_t {
  node = {
    llist = {
      next = 0x0
    },
    {
      u_flags = 48,
      a_flags = {
        counter = 48
      }
    },
    src = 0,
    dst = 0
  },
  func = 0x5,
  info = 0x1009a6b53
}
crash> call_single_data_t 90000000080ac160
struct call_single_data_t {
  node = {
    llist = {
      next = 0x0
    },
    {
      u_flags = 1,
      a_flags = {
        counter = 1
      }
    },
    src = 0,
    dst = 0
  },
  func = 0x90000000012b8b88 <trigger_rx_softirq>,
  info = 0x90000000080abe80
}
```
-->
