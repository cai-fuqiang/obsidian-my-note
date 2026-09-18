---
modified: 2026-09-17T18:25:38+08:00
---
# 保存时机
* syscall
```
entry_SYSCALL_64_switcher
 entry_SYSCALL_64_switcher_safe_stack
   	movq	TSS_extra(pvcs), %rdi
	movl	$((__USER_DS << 16) | __USER_CS), PVCS_user_cs(%rdi)
	movl	%r11d, PVCS_eflags(%rdi)
	movq	%rcx, PVCS_rip(%rdi)
	movq	%rcx, PVCS_rcx(%rdi)
	movq	%r11, PVCS_r11(%rdi)
```