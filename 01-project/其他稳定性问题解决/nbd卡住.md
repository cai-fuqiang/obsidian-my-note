---
created: 2026-09-11T17:55:08+08:00
modified: 2026-09-11T17:55:08+08:00
---
# 现象

有两块盘 `iostat` 卡住, 并且
```
Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
nbd119           0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00 101.90
...
nbd129           0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00 101.90
...

```

qemu进程D住,

```
root     4105301  0.2  0.0      0     0 ?        D    Sep08  12:05 [qemu-system-x86]
```
# dmesg 异常打印
```
[root@11-213-1-135 17:53:54 ~]# dmesg -T |grep 'Dead connection'
[Wed Sep  9 14:00:11 2026] block nbd129: Dead connection, failed to find a fallback
[Wed Sep  9 14:00:12 2026] block nbd119: Dead connection, failed to find a fallback
```


# 调试分析

```
crash> dev -d |grep nbd119
   43 ffff88ab4a0bac00   nbd119     ffff88ab4a0b5b40       2     1     1
   
crash> request_queue.tag_set ffff88ab4a0b5b40
  tag_set = l0xffff88a5253b5a00,
  
crash> nbd_device.config,index,tag_set.nr_hw_queues 0xffff88a5253b5a00
  config = 0xffff88ac8a6dff00,
  index = 119,
  tag_set.nr_hw_queues = 1,
  
crash> nbd_config.num_connections,live_connections 0xffff88ac8a6dff00
  num_connections = 1,
  live_connections = {
    counter = 0
  },
```

