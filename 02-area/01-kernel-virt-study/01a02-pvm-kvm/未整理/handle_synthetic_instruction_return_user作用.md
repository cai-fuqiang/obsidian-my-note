---
modified: 2026-09-04T15:44:00+08:00
---
# 作用
guest smod 当处理完syscall想返回用户态时，不能通过 `iret` 直接返回。而是再次调用 `syscall` 让KVM模拟 "iret" 的流程，而kvm需要知道这个`"iret" (syscall)`的位置, 于是guest通过设置半虚拟化 MSR -- `MSR_PVM_RETU_RIP` 来 标记该位置。

# 大致流程


# ref
```
handle_exit_syscall
=> if rip == pvm->msr_retu_rip_plus2
   => handle_synthetic_instruction_return_user
```