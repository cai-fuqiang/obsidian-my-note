---
data: 2026-07-30
问题分类: softlockup/虚拟机负载高
是否定位成功: true
目前结论: CPU 2 等待CPU1 完成ipi callback，CPU 1 已经完成。问题原因估计是和isolate的错误配置有关系
is_issue: true
instance: i-23m7r699sd
share_link: https://share.note.sx/lsuor494#NB96oGIvyGEa+kF3dnIgrw
share_updated: 2026-08-20T16:20:55+08:00
---
# 问题现象

```
crash> bt
PID: 62       TASK: 9000000104192400  CPU: 2    COMMAND: "kswapd0"
 #0 [90000001003bbad0] panic at 90000000015aa378
 #1 [90000001003bbb60] watchdog_timer_fn at 900000000038fb68
 #2 [90000001003bbba0] __run_hrtimer at 9000000000331014
 #3 [90000001003bbbe0] __hrtimer_run_queues at 90000000003312d0
 #4 [90000001003bbc40] hrtimer_interrupt at 9000000000331b8c
 #5 [90000001003bbcd0] constant_timer_interrupt at 9000000000228104
 #6 [90000001003bbce0] __handle_irq_event_percpu at 90000000002e95f0
 #7 [90000001003bbd30] handle_irq_event_percpu at 90000000002e97c4
 #8 [90000001003bbd50] handle_percpu_irq at 90000000002f1578
 #9 [90000001003bbd70] handle_irq_desc at 90000000002e8c8c
#10 [90000001003bbd80] handle_cpu_irq at 9000000000d380ec
#11 [90000001003bbdb0] handle_loongarch_irq at 90000000015d02dc
#12 [90000001003bbdd0] do_vint at 90000000015d03c4
#13 [90000001003bbe00] _handle_vint at 90000000002222e4
#14 [90000001003bbf40] handle_softirqs at 9000000000258cc4
#15 [90000001003bbfe0] irq_exit_rcu at 9000000000259288
#16 [90000001003bbff0] do_vint at 90000000015d0390
#17 [9000000104177670] smp_call_function_many_cond at 900000000034eaa0
#18 [9000000104177720] on_each_cpu_cond_mask at 900000000034ec80
#19 [9000000104177730] flush_tlb_page at 9000000000233e34
#20 [9000000104177780] ptep_clear_flush at 90000000005317a0
#21 [9000000104177790] try_to_migrate_one at 9000000000536654
#22 [90000001041778b0] rmap_walk_anon at 90000000005338b0
#23 [9000000104177920] try_to_migrate at 9000000000536d4c
#24 [9000000104177970] split_huge_page_to_list_to_order at 90000000005a81e0
#25 [9000000104177a40] deferred_split_scan at 90000000005a8878
#26 [9000000104177ad0] do_shrink_slab at 90000000004db614
#27 [9000000104177b50] shrink_slab_memcg at 90000000004dc078
#28 [9000000104177c10] shrink_node_memcgs at 90000000004d7f04
#29 [9000000104177c70] shrink_node at 90000000004d8010
#30 [9000000104177cd0] balance_pgdat at 90000000004d86b0
#31 [9000000104177e00] kswapd at 90000000004d8b80
#32 [9000000104177e60] kthread at 9000000000284790
#33 [9000000104177ea0] ret_from_kernel_thread at 90000000015d1348
#34 [9000000104177ec0] ret_from_kernel_thread_asm at 90000000002220b8
```

# 初步分析

触发 `softlockup`的pc和 [[2026-07-28-i-23m7r699sd-softlockup]] 相同，所以我们来总结下部分寄存器
```
crash> p *(struct pt_regs *)(0x9000000104177670-sizeof(struct pt_regs)) -x
$5 = {
  regs = {0x0, 0x900000000034ea74, 0x9000000104174000, 0x9000000104177670, 0x1, 0x1, 0x1, 0x1, 0x90000001002385a8, 0x9000000000641274, 0x2, 0x7, 0x1, 0x900000000806ff60, 0x1, 0x90000001041b57d0, 0x90000001041b57c0, 0x3ff, 0x56ad, 0x800000000000, 0xffff800000000000, 0x90000000002222e8, 0x90000000080eff60, 0x90000000025b49a0, 0x90000000080aba80, 0x90000000025b9180, 0xb4, 0x1, 0x9000000000233f00, 0x9000000003474000, 0x90000000025b49a0, 0x9000000104177800},
  orig_a0 = 0x9000000000233f00,
  csr_era = 0x900000000034eaa0,
  csr_badvaddr = 0x0,
  csr_crmd = 0xb0,
  csr_prmd = 0x4,
  csr_euen = 0x0,
  csr_ecfg = 0x71c3d,
  csr_estat = 0x8,
  __last = 0x9000000104177670
}
```

| reg | 表示                                 | alias | val                |
| --- | ---------------------------------- | ----- | ------------------ |
| t1  | &csd                               | r13   | 0x900000000806ff60 |
| t0  | csd.node.u_flags & CSD_FLAG_LOCK的值 | r12   | 1                  |
| a0  | 等待的cpu                             | r4    | 1                  |
此时等待`CPU 1`

查看`CPU1` 堆栈:
```
PID: 16       TASK: 9000000100661240  CPU: 1    COMMAND: "rcu_sched"
 #0 [90000001006ebbf0] __switch_to at 90000000002260bc
 #1 [90000001006ebbf0] __schedule at 90000000015d6848
 #2 [90000001006ebc90] schedule at 90000000015d6e14
 #3 [90000001006ebca0] schedule_timeout at 90000000015deda0
 #4 [90000001006ebd30] rcu_gp_fqs_loop at 900000000030b480
 #5 [90000001006ebde0] rcu_gp_kthread at 900000000030ddf8
 #6 [90000001006ebe60] kthread at 9000000000284790
 #7 [90000001006ebea0] ret_from_kernel_thread at 90000000015d1348
 #8 [90000001006ebec0] ret_from_kernel_thread_asm at 90000000002220b8
```

查看CPU 1 寄存器
```
 CSR000: CRMD   b0               PRMD   4                EUEN   0                MISC   0
 CSR004: ECFG   71c3d            ESTAT  818              ERA    90000000006aae18 BADV   5555880c4058
 CSR008: BADI   2b0000
 CSR012: EENTRY 9000000100a70000
 CSR016: TLBIDX e000000          TLBEHI 5555880c4000     TLBELO0 0               TLBELO1 0
 CSR024: ASID   a02d1            PGDL   90000001071f4000 PGDH   9000000003460000 PGD    0
 CSR028: PWCL   5e56e            PWCH   10002e4          STLBPS e                RVACFG 0
 CSR032: CPUID  1                PRCFG1 72f8             PRCFG2 3ffff000         PRCFG3 8073f2
 CSR048: SAVE0  9000000118515ac0 SAVE1  89b              SAVE2  0                SAVE3  6928000
 CSR052: SAVE4  0                SAVE5  0                SAVE6  0                SAVE7  0
 CSR064: TID    1                TCFG   5d239            TVAL   ffffffffffff     CNTC   ffffffff96874378
```

| reg   | val | bit            |
| ----- | --- | -------------- |
| ESTRT | 818 | 11(TIMER)      |
| CRMD  | b0  | bit(2) = 0 关中断 |

进一步查看, cpu 2 CFD 有哪些CPU没有处理:
```
crash> p ((call_single_data_t *)(0x9000000001747f60+__per_cpu_offset[0]))->node->u_flags
$4 = 0
crash> p ((call_single_data_t *)(0x9000000001747f60+__per_cpu_offset[1]))->node->u_flags
$5 = 0
crash> p ((call_single_data_t *)(0x9000000001747f60+__per_cpu_offset[2]))->node->u_flags
$6 = 0
crash> p ((call_single_data_t *)(0x9000000001747f60+__per_cpu_offset[3]))->node->u_flags
$7 = 0
```

> [!summary] 发现CPU 0, 1 ,3 都被处理
> 

# 重启物理机后查看负载

发现再出问题时, CPU 被steal.

```
[root@g2-loong-loongson-11-211-129-111 ~]# sar -u
Linux 6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64 (g2-loong-loongson-11-211-129-111.vm-17)         07/30/2026      _loongarch64_   (4 CPU)

02:40:05 AM  LINUX RESTART      (4 CPU)

02:50:09 AM     CPU     %user     %nice   %system   %iowait    %steal     %idle
03:00:14 AM     all      0.90      0.03      1.09      0.06      0.00     97.92
03:10:19 AM     all      0.65      0.00      0.73      0.01      0.00     98.60
03:20:24 AM     all      0.70      0.00      0.88      0.01      0.00     98.41
03:30:09 AM     all      4.31      0.02      6.08     22.92      3.05     63.62
03:40:04 AM     all      7.25      0.00     14.79     61.56     16.20      0.21
03:50:10 AM     all      6.38      0.00     14.85     61.31     17.29      0.16
04:00:09 AM     all      6.41      0.00     14.98     59.99     18.45      0.16
04:10:20 AM     all      5.97      0.00     13.22     63.29     17.38      0.14
04:20:25 AM     all      5.92      0.00     14.81     52.40     26.80      0.07
04:30:01 AM     all      5.75      0.00     15.28     48.36     30.56      0.04
04:40:07 AM     all      5.61      0.03     15.12     47.88     31.32      0.04
04:50:14 AM     all      5.74      0.00     15.44     46.62     32.17      0.04
05:00:09 AM     all      5.57      0.00     15.25     47.67     31.46      0.05
05:10:25 AM     all      5.64      0.00     15.48     48.53     30.29      0.05
05:20:02 AM     all      5.12      0.00     14.48     48.00     32.35      0.05
05:30:09 AM     all      3.69      0.00     18.15     23.48     54.57      0.11
05:40:01 AM     all      3.37      0.00     17.54     26.02     52.99      0.08
05:50:15 AM     all      3.35      0.04     16.98     27.08     52.47      0.08
06:00:09 AM     all      3.40      0.00     17.36     24.90     54.25      0.09
06:10:20 AM     all      3.13      0.00     18.45     19.27     59.03      0.12
06:20:15 AM     all      3.15      0.00     18.62     16.24     61.80      0.18
06:30:11 AM     all      2.70      0.00     19.54      9.82     67.59      0.35
06:40:26 AM     all      2.85      0.00     19.55     11.39     65.99      0.24
06:50:01 AM     all      2.50      0.00     19.60     10.41     67.15      0.34
07:00:03 AM     all      2.16      0.04     21.01      5.90     70.45      0.45
07:10:09 AM     all      2.19      0.04     22.06      4.17     71.15      0.39
07:20:24 AM     all      2.30      0.00     21.03      6.08     70.18      0.41
07:30:11 AM     all      2.30      0.00     20.87      7.68     68.77      0.38
07:40:07 AM     all      2.43      0.00     20.23      9.79     67.27      0.27
07:50:15 AM     all      1.35      0.00     27.75      1.29     69.44      0.18
```

# 下一步计划

> [!todo] 几次都出现在kswapd，下一步将进一步评估每次kswapd调度执行的时间。

# 附录
## CPU0, 3 堆栈
> [!tip] CPU0, 3 堆栈collapse: close
> 
> ```
> crash> bt -c 3
> PID: 8002     TASK: 900000013ab73640  CPU: 3    COMMAND: "IO_task /dev/vd"
> #0 [900000000f147ec0] _handle_lsx at 9000000000223158
> crash> bt -c 0
> PID: 8017     TASK: 900000013ae67fc0  CPU: 0    COMMAND: "IO_task /dev/vd"
> #0 [900000000f3cfec0] _handle_lasx at 9000000000223450
> ```
 