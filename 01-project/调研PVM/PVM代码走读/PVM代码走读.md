# pvm_vcpu_run
```
pvm_vcpu_run
=> pvm_set_host_cr3
   => pvm_set_host_cr3_for_hypervisor
   => pvm_set_host_cr3_for_guest
```
# pvm_setup_user_return_msrs
```sh
pvm_setup_user_return_msrs
# PVM中 MSR_LSTAR位于index 0
=> kvm_add_user_return_msr(MSR_LSTAR)
   => kvm_uret_msrs_list[kvm_nr_uret_msrs] = msr
   => return kvm_nr_uret_msrs++
=> kvm_add_user_return_msr(MSR_TSC_AUX)
```
# pvm_prepare_switch_to_guest
```sh
pvm_prepare_switch_to_guest
# 设置 LSTAR
=> kvm_set_user_return_msr(0, (u64)entry_SYSCALL_64_switcher, -1ull)
   # guest如果调用syscall, 直接跳转到 entry_SYSCALL_64_switcher
   # 在kvm_on_user_return时候，再赋值回去
   => err = wrmsrl_safe(kvm_uret_msrs_list[slot], value)
```
# entry_SYSCALL_64_switcher
```sh
# NOTE
entry_SYSCALL_64_switcher
# 切换到host的 gs
=> swapgs
# syscall不会自动load kernel sp, 所以这里是guest 的 rsp
# 将该rsp保存到 TSS_sp2
=> movq %rsp, PER_CPU_VAR(cpu_tss_rw + TSS_sp2)
# 加载内核栈
=> movq PER_CPU_VAR(cpu_tss_rw + TSS_sp0), %rsp
# 在内核栈中构造类似于int 0x80 的现场（准备pt_regs)
=> pushq	$__USER_DS				/* pt_regs->ss */
   pushq	PER_CPU_VAR(cpu_tss_rw + TSS_sp2)	/* pt_regs->sp */
   pushq	%r11					/* pt_regs->flags */
   pushq	$__USER_CS				/* pt_regs->cs */
   pushq	%rcx					/* pt_regs->ip */
   pushq	%rdi					/* put rdi on ORIG_RAX */
# 接下来要模拟syscall指令，并引导进入guest的smod(super)
# SWITCH_FLAGS_NO_DS_TO_SMOD 是用来判断能不能直接direct switch to SMOD
# 如果整个的test为真, 则跳转 L_switcher_check_return_umod_instruction
=> testq $SWITCH_FLAGS_NO_DS_TO_SMOD, TSS_extra(switch_flags)
   jnz	.L_switcher_check_return_umod_instruction
# 能走到这里说明一定是umod->smod, 先将umod的相关寄存器存储下来，主要包括syscall
# save umod 的上下文寄存器, rcx(save user rip), r11(save user rflags)
=> 	movq	TSS_extra(pvcs), %rdi
	movl	$((__USER_DS << 16) | __USER_CS), PVCS_user_cs(%rdi)
	movl	%r11d, PVCS_eflags(%rdi)
	movq	%rcx, PVCS_rip(%rdi)
	movq	%rcx, PVCS_rcx(%rdi)
	movq	%r11, PVCS_r11(%rdi)

# 切换 umod -> smod, 主要工作:
# 1. 翻转 switch_flags (SMOD|UMOD)
# 2. 切换 切换CR3 -> smod
## TODO : 稍后，我们来看CR3
=> 	xorb	$SWITCH_FLAGS_MOD_TOGGLE, TSS_extra(switch_flags)
	movq	TSS_extra(smod_cr3), %rcx
	movq	%rcx, %cr3
# smod_entry 为 guest 系统调用的入口
=>  movq	TSS_extra(smod_entry), %rcx
    # 先将rcx 放到内核栈pt_regs的 RIP处（因为下面要用到rcx)
	movq	%rcx, RIP-ORIG_RAX(%rsp)
# 先将 smod_gsbase获取到r11中(这个是smod的 gsbase)
=>	movq	TSS_extra(smod_gsbase), %r11
# 切换到guest gs(user)
	swapgs
# 保存guest user gs 到 PVCS中
=> 	rdgsbase %rcx
	movq	%rcx, PVCS_user_gsbase(%rdi)
# 切换到guest smod gs
	wrgsbase %r11

# 为模拟syscall 作准备
=>	popq	%rdi
    # r11 保存固定的 eflags
	movq	$SWITCH_ENTER_EFLAGS_FIXED, %r11
	# 将堆栈里面的rcx 在放到 rcx寄存器中(rcx = guest syscall entry)
	# 为sysretq作准备（sysretq 从 r11 中恢复 rflags，从 r11)
	movq	RIP-RIP(%rsp), %rcx
# 将堆栈上的rsp(guest umod rsp), 再赋值给%rsp
    movq	RSP-RIP(%rsp), %rsp
# 调用sysretq
	sysretq
```

> [!important] 这段代码的 NB 之处, 在于其只借用了syscall 的上下文寄存器(例如rcx，rsp)，并未暂存和修改其他寄存器，也就意味着这些寄存器可以直接传递给 `guest smod`
## L_switcher_check_return_umod_instruction
```sh
# 走到这里可能有两个原因
# 1. 本次syscall是从 guest smod 调用
# 2. 本次syscall 需要hypervisor进行模拟
L_switcher_check_return_umod_instruction

#  判断 是否不能切到umod
#  如果不能，则说明是 是 umod 需要hypervisor 模拟
=> 	testq	$SWITCH_FLAGS_NO_DS_TO_UMOD, TSS_extra(switch_flags)
	jnz	.L_switcher_return_to_hypervisor

#  走到这里，说明可以切换到umod，则说明是smod->umod的切换
#  如果 rcx 不等于 retu_rip， 则说明guest 使用的有问题，交给hypervisor处理
# （可能是注入异常)
=>	cmpq	%rcx, TSS_extra(retu_rip)
	jne	.L_switcher_return_to_hypervisor
#   TODO,回头再看这个。这里比较了 pvcs 中的user_cs
=>	movq	TSS_extra(pvcs), %rdi
	cmpl	$((__USER_DS << 16) | __USER_CS), PVCS_user_cs(%rdi)
	jne	.L_switcher_return_to_hypervisor
# 走到这里, 说明不需要hypervisor 处理，可以direct switch 到 umod
# 切换到guest的gs
=>	swapgs
# 获取umod gs
=> 	movq	PVCS_user_gsbase(%rdi), %rcx
	canonical_rcx
    # 写入gs寄存器,
	wrgsbase %rcx
# 获取rcx 和 r11, 并且将rcx和r11 放到堆栈中的 rflags, rip处，
# 以便方便通过iret 返回
=> 	movl	PVCS_eflags(%rdi), %r11d
	movq	%r11, EFLAGS-ORIG_RAX(%rsp)
	movq	PVCS_rip(%rdi), %rcx
	movq	%rcx, RIP-ORIG_RAX(%rsp)
	movq	PVCS_rcx(%rdi), %rcx
	movq	PVCS_r11(%rdi), %r11
	# popq rdi, iret要求sp指向RIP的位置
	popq	%rdi
.L_switcher_return_to_guest:
    # SWITCH_ENTER_EFLAGS_ALLOWED : Guest umod 允许使能的eflags
	andq	$SWITCH_ENTER_EFLAGS_ALLOWED, EFLAGS-RIP(%rsp)
	# SWITCH_ENTER_EFLAGS_ALLOWED: Guest umod 必须使能的eflags
	orq	$SWITCH_ENTER_EFLAGS_FIXED, EFLAGS-RIP(%rsp)
	# 如果使能了 RF, TF 不能通过 sysret返回，必须通过iret
	testq	$(X86_EFLAGS_RF|X86_EFLAGS_TF), EFLAGS-RIP(%rsp)
	jnz	native_irq_return_iret
	# 如果r11 != eflags 不能通过sysret返回, 必须通过iret(TODO待研究)
	cmpq	%r11, EFLAGS-RIP(%rsp)
	jne	native_irq_return_iret
    # 同上 
	cmpq	%rcx, RIP-RIP(%rsp)
	jne	native_irq_return_iret
	/*
	 * On Intel CPUs, SYSRET with non-canonical RCX/RIP will #GP
	 * in kernel space.  This essentially lets the guest take over
	 * the host, since guest controls RSP.
	 */
	canonical_rcx
	# 如果调整后的 rcx 没变，直接通过sysret返回
	cmpq	%rcx, RIP-RIP(%rsp)
	je	.L_switcher_sysretq

    # 如果调整前相同，而调整后不同，则恢复调整前的rip->rcx，并通过iret返回。
	/* RCX matches for RIP only before RCX is canonicalized, restore RCX and do IRET. */
	movq	RIP-RIP(%rsp), %rcx
	jmp	native_irq_return_iret
```

## L_switcher_sysretq
```
.L_switcher_sysret
	UNWIND_HINT_IRET_REGS
	/* now everything is ready for sysretq except for %rsp */
	movq	RSP-RIP(%rsp), %rsp
	/* No instruction can be added between seting the guest %rsp and doing sysretq */
	sysretq
```
## L_switcher_return_to_hypervisor
```
.L_switcher_return_to_hypervisor:
	popq	%rdi					/* saved rdi */
	pushq	$0					/* pt_regs->orig_ax */
	movl	$SWITCH_EXIT_REASONS_SYSCALL, 4(%rsp)

	PUSH_AND_CLEAR_REGS
	jmp	switcher_return_from_guest
```

### swither_return_from_guest
```sh
swither_return_from_guest
# 将cr3切换到host_cr3
=>	movq	TSS_extra(host_cr3), %rax
	movq	%rax, %cr3
# 将 rsp 切换到host rsp, 并将 host_rsp赋值为0， 说明是退回到 host hypervisor, 不在swither中
=> 	movq	%rsp, %rax
	movq	TSS_extra(host_rsp), %rsp
	movq	$0, TSS_extra(host_rsp)

# 为什么这里只restore 这几个寄存器
=> 	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	RET
```

> [!faq] 为什么这里只restore 这几个寄存器? 
> 这些寄存器是SysV ABI 规定的「被调用者保存寄存器」(callee-saved)
## native_irq_return_iret
```cpp
SYM_INNER_LABEL(native_irq_return_iret, SYM_L_GLOBAL)
	ANNOTATE_NOENDBR // exc_double_fault
	/*
	 * This may fault.  Non-paranoid faults on return to userspace are
	 * handled by fixup_bad_iret.  These include #SS, #GP, and #NP.
	 * Double-faults due to espfix64 are handled in exc_double_fault.
	 * Other faults here are fatal.
	 */
    iretq
```
# switcher_enter_guest
```sh
switcher_enter_guest
# 为什么只保留这几个寄存器
=>	pushq	%rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
# 保存host_rsp 方便之后跳转回来
=>	movq	%rsp, TSS_extra(host_rsp)
# 切换sp为 sp0
=>  movq	PER_CPU_VAR(cpu_tss_rw + TSS_sp0), %rdi
    # 将sp切换到 pt_regs处
	subq	$FRAME_SIZE, %rdi
	movq	%rdi, %rsp
# 准备切换到 guest, 首先切换guest cr3
=>  movq	TSS_extra(enter_cr3), %rax
	movq	%rax, %cr3
	/* Load guest registers. */
	# 切换guest regs
	POP_REGS
	# 这里为什么要自增rsp
	addq	$8, %rsp

	/* Switch to guest GSBASE and return to guest */
	# 切换到guest 的gs, 这里怎么判断的是切换到guest gs还是用户态的gs呢, TODO
	swapgs
	# 准备跳转到 guest
	jmp	.L_switcher_return_to_guest
```

# guest kernel
## pvm_early_setup
```
pvm_early_setup
=> wrmsrl(MSR_PVM_VCPU_STRUCT, __pa(this_cpu_ptr(&pvm_vcpu_struct)));
=> wrmsrl(MSR_PVM_EVENT_ENTRY, (unsigned long)(void *)pvm_early_kernel_event_entry - 512);
```

## 