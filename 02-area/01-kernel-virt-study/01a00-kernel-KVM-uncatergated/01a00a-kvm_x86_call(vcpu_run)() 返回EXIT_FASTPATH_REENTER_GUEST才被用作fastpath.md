---
modified: 2026-09-10T18:01:28+08:00
---
# ref
```
vcpu_enter_guest
=> for(;;)
   => exit_fastpath = kvm_x86_call(vcpu_run)()
   => if likely(exit_fastpath != EXIT_FASTPATH_REENTER_GUEST)
      => break
```