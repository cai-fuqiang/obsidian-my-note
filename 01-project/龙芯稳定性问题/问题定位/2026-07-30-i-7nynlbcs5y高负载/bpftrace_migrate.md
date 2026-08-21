---
share_link: https://share.note.sx/k5cj0hon#/YZvLBw2vF5piDIHSkRZuA
share_updated: 2026-07-31T11:00:33+08:00
---
```
tracepoint:sched:sched_migrate_task
{
    if (args->orig_cpu == 40 ||
	args->orig_cpu == 52 ||
	args->orig_cpu == 51 ||
	args->orig_cpu == 43 ||
        args->dest_cpu == 40 ||
	args->dest_cpu == 52 ||
	args->dest_cpu == 51 ||
	args->dest_cpu == 43)
    {
	printf(" pid (%d) comm(%s) orig_cpu(%d) dest_cpu(%d)\n", pid, comm, args->orig_cpu, args->dest_cpu);
	print(kstack());
    }
}

interval:s:60
{
	printf("test ....\n");
}
```