# D进程信息
```
[root@localhost ~]# ps aux |grep D
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root        1563  0.0  0.0   2312  1044 pts/0    D+   03:08   0:00 ./jddsctl snapshot create /dev/vdb periodic_snap_1
root        1565  0.0  0.0   2964  2140 pts/0    D+   03:08   0:00 ./bin/direct_aio /dev/vdb 640,128 -b 4096 -c 0x5a -w
[root@localhost ~]# cat /proc/1563
cat: /proc/1563: Is a directory
[root@localhost ~]# cat /proc/1563/stack
[<0>] blk_mq_freeze_queue_wait+0x68/0xa0
[<0>] bio_monitor_freeze_bdev_io+0x6b/0x1d0 [jdds]
[<0>] jdds_create_snapshot+0xd9/0x410 [jdds]
[<0>] jdds_ioctl+0x6a5/0x930 [jdds]
[<0>] __se_sys_ioctl+0x8b/0xc0
[<0>] do_syscall_64+0x55/0x100
[<0>] entry_SYSCALL_64_after_hwframe+0x78/0xe2
[root@localhost ~]# cat /proc/1565/stack
[<0>] __bio_queue_enter+0x134/0x1c0
[<0>] __submit_bio+0x41/0xa0
[<0>] __submit_bio_noacct+0x81/0x210
[<0>] __blkdev_direct_IO_async+0x18b/0x1c0
[<0>] blkdev_write_iter+0x1d7/0x2a0
[<0>] aio_write+0x11e/0x220
[<0>] io_submit_one+0xda/0x350
[<0>] __se_sys_io_submit+0x74/0x150
[<0>] do_syscall_64+0x55/0x100
[<0>] entry_SYSCALL_64_after_hwframe+0x78/0xe2
```



# 相关commit
```
commit cc9c884dd7f4f036965e23f5445f838db316eb46
Author: Christoph Hellwig <hch@lst.de>
Date:   Wed Sep 29 09:12:37 2021 +0200

    block: call submit_bio_checks under q_usage_counter
```