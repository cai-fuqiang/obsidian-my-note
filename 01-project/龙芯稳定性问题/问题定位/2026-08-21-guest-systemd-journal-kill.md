---
data: 2026-08-21
问题分类: guest app SIGART
是否定位成功: true
目前结论: 暂无
is_issue: true
instance: many
share_link: https://share.note.sx/4dcpwtd0#25dyo79p7FflYyJDXZRyqQ
share_updated: 2026-08-21T19:43:07+08:00
---
# i-jjinv5uhk2
```
         systemd-1       [002] d.... 53381.424981: signal_generate: sig=6 errno=0 code=0 comm=systemd-journal pid=582 grp=1 res=0
         systemd-1       [002] d.... 53381.424988: <stack trace>
 => trace_event_raw_event_signal_generate
 => __send_signal_locked
 => do_send_sig_info
 => kill_pid_info
 => sys_pidfd_send_signal
 => do_syscall
 => handle_syscall
 => 0x6f72506e776f6e6b
```

# i-gxpy9uz7wm
```
         systemd-1       [003] d.... 53361.756623: signal_generate: sig=6 errno=0 code=0 comm=systemd-timesyn pid=777 grp=1 res=0
         systemd-1       [003] d.... 53361.756630: <stack trace>
 => trace_event_raw_event_signal_generate
 => __send_signal_locked
 => do_send_sig_info
 => kill_pid_info
 => sys_pidfd_send_signal
 => do_syscall
 => handle_syscall
 => 0x3a64695072656361
         systemd-1       [003] d.... 53424.008783: signal_generate: sig=6 errno=0 code=0 comm=systemd-journal pid=575 grp=1 res=0
         systemd-1       [003] d.... 53424.008791: <stack trace>
 => trace_event_raw_event_signal_generate
 => __send_signal_locked
 => do_send_sig_info
 => kill_pid_info
 => sys_pidfd_send_signal
 => do_syscall
 => handle_syscall
 => 0x3a64695072656361
```
# i-zgkukcqthm

```
         systemd-1       [003] d.... 52271.121098: signal_generate: sig=6 errno=0 code=0 comm=systemd-timesyn pid=768 grp=1 res=0
         systemd-1       [003] d.... 52271.121105: <stack trace>
 => trace_event_raw_event_signal_generate
 => __send_signal_locked
 => do_send_sig_info
 => kill_pid_info
 => sys_pidfd_send_signal
 => do_syscall
 => handle_syscall
 => 0x540a32093a646950

```