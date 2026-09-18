---
share_link: https://share.note.sx/zgdoo2q8#GuMIQEQFICFx9MkfZ1uN9w
share_updated: 2026-08-27T21:53:54+08:00
modified: 2026-09-17T10:52:08+08:00
---
# 测试结果

| 测试项             | 每次world switch(guest->hypervisor->guest) cycle |
| --------------- | ---------------------------------------------- |
| ==KVM-on-BARE== | ==1614==                                       |
| KVM-on-KVM      | 19982                                          |
| PVM-on-BARE     | <mark style="background:#affad1">1405</mark>   |
| ==PVM-on-KVM==  | ==3073==                                       |

^76e8c3

> [!summary] 
> 结果很意外
> 1. `PVM-on-KVM`的性能比`KVM-on-BARE`性能要低不少。原因未知。(这可能是个优化点)
> 2. `PVM-on-BARE` 性能仅仅比`KVM-on-BARE`的性能高一点。（intel的vmcs 优化还是nb, 估计在加了很多cache)

# 附录
## 具体日志
* PVM-on-KVM
```
[   72.210456] vmexit_timing: mode=pvm-syscall-hypercall cpu=0 loops=10000 total_cycles=30737758 avg_cycles=3073 last_ret=0
[   72.210463] vmexit_timing: host_tsc_sample=902853843424
```

* KVM-on-KVM
```
[   37.079637] vmexit_timing: mode=pvm-syscall-hypercall cpu=0 loops=100000 total_cycles=306710181 avg_cycles=3067 last_ret=0
[   37.079645] vmexit_timing: host_tsc_sample=64474443197118
```

* KVM-on-BARE
```
[   21.608214] vmexit_timing: mode=kvm-vmcall cpu=0 loops=10000 total_cycles=199829026 avg_cycles=19982 last_ret=0
[   21.608221] vmexit_timing: host_tsc_sample=4360953282181
```

* PVM-on-BARE
```
[   59.875728] vmexit_timing: mode=pvm-syscall-hypercall cpu=0 loops=100000 total_cycles=140551334 avg_cycles=1405 last_ret=0
[   59.875735] vmexit_timing: host_tsc_sample=3091147118236747
```