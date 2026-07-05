```
BEGIN {
        @consume_entry_addr=0;
        @task_is_bash=0;
        @unwind_state=0;
        @orc_ip;
}

kprobe:arch_stack_walk_reliable
{
        $task_struct=(struct task_struct *)arg2;

        if ($task_struct->comm == "python") {
                @task_is_bash=1;
                print(kstack());
        }
        printf("enter arch_stack_walk_reliable task(%s) pid (%d) \n", $task_struct->comm, $task_struct->pid);
}

kretprobe:arch_stack_walk_reliable
{
        printf("arch_stack_walk_reliable ret : %d\n", retval);
        //if (@unwind_state != 0 && @task_is_bash == 1) {
        // printf("unwind state is %lx\n", @unwind_state);
        // $unwind_state_l = (struct unwind_state *)@unwind_state;
        // printf("unwind ip (%lx) sp(%lx) bp(%lx) error(%d) \n",
        // $unwind_state_l->ip,
        // $unwind_state_l->sp,
        // $unwind_state_l->bp,
        // $unwind_state_l->error);
        //}
        @task_is_bash=0;
        @unwind_state=0;
}

kprobe:stack_trace_consume_entry
{
        @consume_entry_addr=arg1;
        if (@task_is_bash == 1) {
                printf("consume_entry :addr %lx\n", arg1);
        }
}

kretprobe:stack_trace_consume_entry
{
        if (@task_is_bash == 1) {
                printf("consume_entry addr(%lx) ret(%d)\n", @consume_entry_addr, retval);
                @consume_entry_addr=0;
        }
}

kprobe:unwind_get_return_address
{
        if (@task_is_bash) {
                @unwind_state=arg0;
        }
}

kretprobe:unwind_get_return_address
{
        if (@task_is_bash) {
                printf("unwind_get_return_address address(%lx)\n", retval);
        }
}

kretprobe:unwind_next_frame
{
        if (@task_is_bash) {
                printf("unwind_next_frame ret(%d)\n", retval);
        }
}
kprobe:__orc_find
{
        @orc_ip=arg3
}
kretprobe:__orc_find
{
        if (@task_is_bash) {
                printf("orc_find ret(%lx) ip(%lx)\n", retval, @orc_ip);
        }
}
```

