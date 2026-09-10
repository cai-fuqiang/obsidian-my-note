---
modified: 2026-09-04T15:44:12+08:00
---
sp0初始化:
```cpp
cpu_init
=> load_sp0((unsigned long)(cpu_entry_stack(cpu) + 1));
   => native_load_sp0
      => this_cpu_write(cpu_tss_rw.x86_tss.sp0, sp0);
```

参考pvm代码, 以 `#PF`为例

* host usespace -> kernel space

```cpp
.macro idtentry_body vector cfunc has_error_code:req
=> call error_entry
   => jmp    sync_regs
      => struct pt_regs *regs = (struct pt_regs *)current_top_of_stack() - 1
      => if (regs != eregs)
         => *regs = *eregs
         ## rax = regs
         => return regs
=> movq %rax, %rsp
=> move %rsp, %rdi
=> call \cfunc
```

也就是在调用`cfunc(exc_page_fault)` 之前，先切换到`current_top_of_stack()`所指向的内核栈，==并且将regs也同样copy过去==

* guest -> host

```cpp
.macro idtentry_body vector cfunc has_error_code:req
=> call error_entry
   => jmp    sync_regs
      # 表示是在switcher中
      => if (this_cpu_read(cpu_tss_rw.tss_ex.host_rsp))
         # 这里不copy eregs，而是直接返回
         => return eregs
# 所以这里堆栈还是sp0
=> movq %rax, %rsp
=> cmpq	$0, TSS_extra(host_rsp)
=> jne	.Lpvm_idtentry_body_\@
.Lpvm_idtentry_body_\@:
# 将 \$vector赋值 pt_regs ORIG_RAX
=> movl \$vector, ORIG_RAX+4(%rsp)
=> jmp switcher_return_from_guest
   # 先切换host_cr3, 此时sp 还是sp0的栈
   => movq	TSS_extra(host_cr3), %rax
   => movq	%rax, %cr3
   # 将原来的rsp放到rax中，作为返回值
   => moveq %rsp, %rax
   # 切换到 host_rsp
   => movq	TSS_extra(host_rsp), %rsp
   # 清空 TSS_extra(host_rsp) 表示已经退出了switcher
   => movq	$0, TSS_extra(host_rsp)
   # pop host_rsp 栈中保存的寄存器
   => popq %rbx, r12, r13, r14, r15, rbp
   # 返回到上一级调用(其实是switcher_enter_guest 返回)
   => ret
```

`switcher_enter_guest`的上一级调用者
```cpp
pvm_vcpu_run_noinstr
# 从上面流程可以知道，ret_regs 指向sp0中的eregs，也就是guest的上下文
=> ret_regs =  switcher_enter_guest();
=> pvm->switch_flags = tss_ex->switch_flags;
# 将ret_regs 保存到 vcpu中。
=> save_regs(vcpu, ret_regs);
```