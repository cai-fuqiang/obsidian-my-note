---
share_link: https://share.note.sx/vy5ya5gv#Pjmb2kis9UNXaxsY/nnw9Q
share_updated: 2026-09-01T11:19:38+08:00
modified: 2026-09-17T10:52:13+08:00
---
执行命令: `perf bench syscall all` 命令

| test_item          | basic                                         | getpgid      | fork                                                  | execve                                           |
| :----------------- | :-------------------------------------------- | :----------- | :---------------------------------------------------- | :----------------------------------------------- |
| kvm-on-bare(nopti) | 0.093                                         | 0.087        | 897                                                   | 856                                              |
| kvm-on-kvm(nopti)  | <mark style="background:#affad1">0.077</mark> | 0.075        | 958.427                                               | 1157.592                                         |
| pvm-on-bare(nopti) | <mark style="background:#affad1">0.296        | 0.29</mark>1 | <mark style="background:#ff4d4f">2176.099</mark>      | <mark style="background:#ff4d4f">2153.628</mark> |
| pvm-on-kvm(nopti)  | 0.294                                         | 0.29         | <mark style="background:#ff4d4f">3017.636</mark>      | <mark style="background:#ff4d4f">2634.97</mark>  |
| bare(nopti)        | <mark style="background:#affad1">0.135        | 0.135        | <mark style="background:#d3</mark>f8b6">563.2 </mark> | <mark style="background:#d3f8b6">564.033</mark>  |
| kvm-on-bare        | <mark style="background:#affad1">0.282</mark> | 0.281        | 924.242                                               | 890.997                                          |
| kvm-on-kvm         | 0.248                                         | 0.243        | 992.347                                               | 1174.314                                         |
| pvm-on-bare        | 0.296                                         | 0.29         | 2236.468                                              | 2215.337                                         |
| pvm-on-kvm         | 0.291                                         | 0.289        | 3007.75                                               | 2635.854                                         |

^88d1fd

> [!summary] 
> 1. 无论是 `kvm-on-kvm`, 还是`kvm-on-bare`, 开启pti 会导致一定的性能下降
> 2. 在裸金属中测试, `basic/getpgid` 性能 **居然比 虚拟机中要差** ，而`fork/execve`比虚拟机中要好
> 3. `pvm vm` 开启`nopti` 无提升, 因为 `pvm vm` 会`disable pti`
> 4. `pvm-on-kvm` 在 `basic` 和 `getppid` 性能比`kvm-on-kvm` 使能pti 性能接近（略低) (原因见上一条)
> 5. `pvm-on-kvm` 在`fork` 和`execve` 性能比`kvm-on-kvm`性能低太多了。论文中的说法是，`fork`和`execve`会创建页表映射。但是不访问。

> [!summary] 结论和论文基本一致


# 其他杂记
```
fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl xtopology cpuid tsc_known_freq pni pclmulqdq vmx ssse3 fma cx16 pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm cpuid_fault tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid xsaveopt arat vnmi umip arch_capabilities

fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl xtopology cpuid tsc_known_freq pni pclmulqdq vmx ssse3 fma cx16 pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm cpuid_fault tpr_shadow flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid xsaveopt arat vnmi umip arch_capabilities


[root@localhost clocksource]# dmesg |grep kvm
[    0.000000] kvm-clock: Using msrs 4b564d01 and 4b564d00
[    0.000001] kvm-clock: using sched offset of 7455334157 cycles
[    0.000002] clocksource: kvm-clock: mask: 0xffffffffffffffff max_cycles: 0x1cd42e4dffb, max_idle_ns: 881590591483 ns
[    0.054821] kvm-guest: APIC: eoi() replaced with kvm_guest_apic_eoi_write()
[    0.054833] kvm-guest: KVM setup pv remote TLB flush
[    0.054836] kvm-guest: setup PV sched yield
[    0.136128] kvm-guest: APIC: send_IPI_mask() replaced with kvm_send_ipi_mask()
[    0.136134] kvm-guest: APIC: send_IPI_mask_allbutself() replaced with kvm_send_ipi_mask_allbutself()
[    0.136137] kvm-guest: setup PV IPIs
[    0.323594] clocksource: Switched to clocksource kvm-clock
[    0.667438] systemd[1]: Detected virtualization kvm.
[    2.029410] systemd[1]: Detected virtualization kvm.

[    0.000000] kvm-clock: Using msrs 4b564d01 and 4b564d00
[    0.000001] kvm-clock: using sched offset of 4843504066 cycles
[    0.000003] clocksource: kvm-clock: mask: 0xffffffffffffffff max_cycles: 0x1cd42e4dffb, max_idle_ns: 881590591483 ns
[    0.086947] kvm-guest: APIC: eoi() replaced with kvm_guest_apic_eoi_write()
[    0.086959] kvm-guest: KVM setup pv remote TLB flush
[    0.086962] kvm-guest: setup PV sched yield
[    0.178363] kvm-guest: APIC: send_IPI_mask() replaced with kvm_send_ipi_mask()
[    0.178370] kvm-guest: APIC: send_IPI_mask_allbutself() replaced with kvm_send_ipi_mask_allbutself()
[    0.178373] kvm-guest: setup PV IPIs
[    0.370070] clocksource: Switched to clocksource kvm-clock
[    0.690808] systemd[1]: Detected virtualization kvm.
[    1.924668] systemd[1]: Detected virtualization kvm.
```