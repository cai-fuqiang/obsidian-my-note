---
created: 2026-09-07T15:11:43+08:00
modified: 2026-09-18T18:48:20+08:00
share_link: https://share.note.sx/7nt80c39#mB6UCrpAn9+epruY7NwKCw
share_updated: 2026-09-10T11:02:41+08:00
---
# L0 程序
```bash
#!/usr/bin/env bpftrace

kprobe:native_queued_spin_lock_slowpath {
    @start[tid] = nsecs;
    @spinlock_count[comm] = count();
}

kretprobe:native_queued_spin_lock_slowpath / @start[tid]/ {
    @time_hist = hist(nsecs - @start[tid]);
    delete(@start[tid]);
}
```

# L1 程序
```bash
#!/usr/bin/env bpftrace
//需抓取slowpath
kfunc:vmlinux:__pv_queued_spin_lock_slowpath {
    if (comm == "pf_trigger") {
        @spinlock_count[comm] = count();
        @spinlock_stack[kstack()] = count();
        @start[tid] = nsecs;
    }
}

//kretprobe:native_queued_spin_lock_slowpath / @start[tid]/ {
kretfunc:vmlinux:__pv_queued_spin_lock_slowpath / @start[tid]/ {
    if (comm == "pf_trigger") {
        @time_hist = hist(nsecs - @start[tid]);
        delete(@start[tid]);
    }
}
```

<!--
注意，使用下面程序测试可能会导致host崩溃

```
#!/usr/bin/env bpftrace
kprobe:native_queued_spin_lock_slowpath /cpu >= 0 && cpu < 16/ {
    @start[cpu] = nsecs;
}
kretprobe:native_queued_spin_lock_slowpath /cpu >= 0 && cpu < 16 && @start[cpu]/ {
    @time_hist = hist(nsecs - @start[cpu]);
    delete(@start[cpu]);
}
```
具体原因还未调试
-->