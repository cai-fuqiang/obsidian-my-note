---
share_link: https://share.note.sx/cgeqlqeg#WpkvwzGJO/trRoXJydnswQ
share_updated: 2026-07-31T14:37:56+08:00
---
```
#!/usr/bin/env bpftrace

BEGIN
{
    printf("Tracing sched_switch for PID %d. Hit Ctrl-C to exit.\n", $1);
}

tracepoint:sched:sched_switch
/args->prev_pid == $1 || args->prev_pid == $2 || args->prev_pid == $3 || args->prev_pid == $4/
{
    @stacks[pid, tid, cpu] = count();
}

END
{
    printf("\n=== Switch-out stack counts ===\n");
    print(@stacks);
    clear(@stacks);
}
```