# 代码流程
```
arm_kprobe
  arm_kprobe_ftrace
    register_ftrace_function
	  ftrace_startup
	    __register_ftrace_function
	      ftrace_update_trampoline
	        arch_ftrace_update_trampoline
	          create_trampoline
	            
```


# register_kretprobe
```sh
register_kretprobe
# 居然将pre_handler 赋值为 pre_handler_kretprobe, 这不是参数而是一个kretprobe的
# 内部的符号
=> rp->kp.pre_handler = pre_handler_kretprobe
# 没有post handler
=> rp->kp.post_handler = NULL
=> rp->rh = rethook_alloc(rp, kretprobe_rethook_handler,
              sizeof(struct kretprobe_instance) + rp->data_size,
              rp->maxactive)
=> register_kprobe
```

# register_kprobe
```sh
register_kprobe
=> __register_kprobe
# => 处理 old kprobe, #TODO 
=> arm_kprobe
   # p->flags & KPROBE_FLAG_FTRACE
   => unlikely(kprobe_ftrace(kp))
      => return arm_kprobe_ftrace()
   => __arm_kprobe  
```

## arm_kprobe_ftrace()
```sh
arm_kprobe_ftrace
=> __arm_kprobe_ftrace
   # kprobe可能会指定 post_handler, 但是kretprobe只有pre_handler.
   # 这里为什么要用post_handler来表示??
   # 原因在于post handler 如果不为空，post handler 执行完后，要将ip步进下。
   # TODO 需要看pre handler 和 post handler的处理逻辑
   => ipmodify  = (p->post_handler != NULL);
   # kprobe_ipmodify_ops.flags多了FTRACE_OPS_FL_IPMODIFY
   # xx_ops.func = kprobe_ftrace_handler
   => 	return __arm_kprobe_ftrace(p,
			ipmodify ? &kprobe_ipmodify_ops : &kprobe_ftrace_ops,
			ipmodify ? &kprobe_ipmodify_enabled : &kprobe_ftrace_enabled);
		=> ftrace_set_filter_ip()
		=> register_ftrace_function
		   => register_ftrace_function_nolock()
		      => ftrace_ops_init()
		      => ftrace_startup(ops, 0)
		         => __register_ftrace_function
		            # ops不在kernel的bss段里面, 则说明是动态分配的
		            => if (!is_kernel_core_data(ops))
		               => ops->flags |= FTRACE_OPS_FL_DYNAMIC
		            => add_ftrace_ops(&ftrace_ops_list, ops)
		            => ops->saved_func = ops->func
		         => ftrace_update_trampoline
		            => arch_ftrace_update_trampoline(ops);
		         => ftrace_startup_enable
		            => if (saved_ftrace_func != ftrace_trace_function) 
		               => saved_ftrace_func = ftrace_trace_function;
			           => command |= FTRACE_UPDATE_TRACE_FUNC;
			        => ftrace_run_update_code(command)
			           => stop_machine(__ftrace_modify_code, &command, NULL);
```

## arch_ftrace_update_trampoline

```sh
arch_ftrace_update_trampoline
=> ops->trampoline
   => ops->trampoline = create_trampoline(ops, &size)
      => if (ops->flags & FTRACE_OPS_FL_SAVE_REGS)
         => start_offset = ftrace_regs_caller
         => end_offset = ftrace_regs_caller_end
         => op_offset = ftrace_regs_caller_op_ptr
         => call_offset = ftrace_regs_call
         => jmp_offset = 0
      -> else (略)
      => size = end_offset - start_offset
      # size: sizeof(ftrace_caller code)
      # RET_SIZE: sizeof(iret/retq)
      # sizeof(void *) : sizeof(struct ftrace_ops *)
      => trampoline = alloc_tramp(size + RET_SIZE + sizeof(void *))
         => execmem_alloc_rw(EXECMEM_FTRACE, size)
      => *tramp_size = size + RET_SIZE + sizeof(void *)
      ## COPY ftrace_caller code
      => ret = copy_from_kernel_nofault(trampoline, (void *)start_offset, size);
      # trampoline 末尾存放一个ip ?
      => ip = trampoline+size
      # COPY iret/retq
      # (先不关注retchuck)
      => memcpy(ip, retq, sizeof(retq))
   
   
```

## `__ftrace_modify_code`

```
__ftrace_modify_code
=> ftrace_modify_all_code
   => if (command & FTRACE_UPDATE_TRACE_FUNC)
      => update_ftrace_func(ftrace_ops_list_func);
```


# TODO
* retchuck


