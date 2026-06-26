---
pm-task: true
projectId: "mulztcwamqrn1do4"
parentId:
id: "9xh4t3ccmqrn1wqf"
title: "解决superblock某些字段被赋值为0的问题"
type: "task"
status: "in-progress"
priority: "high"
start: "2026-06-24"
due: "2026-06-25"
progress: 0
assignees: []
tags: ["jdds", "jdstack-job"]
subtaskIds: []
dependencies: []
createdAt: "2026-06-24T05:34:17.847Z"
updatedAt: "2026-06-24T09:37:42.131Z"
timeLogs:
  - date: "2026-06-24"
    hours: 0.1
    note: "简单了解print_hex_dump 用法"
  - date: "2026-06-24"
    hours: 1
    note: ""
---

# 问题描述

触发堆栈

```ad-bug
collapse: closed
[  183.269666] md is ffff8fe02cdad278 b_per_l1(0) e_per_l1(0)
[  183.270997] the addr is ffff8fe01c09b000
[  183.271951] whole page: 000000008374570e: fe ed ba be 00 00 00 02 00 00 00 02 00 00 00 00
[  183.273886] whole page: 00000000e82cce0f: 00 00 00 02 00 00 0a f8 00 00 00 03 00 00 06 a7
[  183.275811] whole page: 000000009803a0e4: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[  183.277740] whole page: 00000000ba255e19: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[  183.279673] the block_per_table :0 entries_per_table:0
[  183.280906] divide error: 0000 [#1] SMP PTI
[  183.281902] CPU: 2 PID: 34446 Comm: sync Kdump: loaded Tainted: G           OE    --------- -  - 4.18.0-193.el8.x86_64 #1
[  183.284454] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS rel-1.15.0-0-g2dd4b9b-prebuilt.qemu.org 04/01/2014
[  183.287041] RIP: 0010:walk_l1t+0x8c/0x17f [jdds]
[  183.288127] Code: 65 28 41 8b 4d 24 48 c7 c7 08 27 79 c0 44 89 e2 89 ce 89 4c 24 04 e8 5a a9 78 e1 8b 4c 24 04 31 d2 48 c7 c7 18 39 79 c0 89 c8 <41> f7 f4 89 c6 89 44 24 04 e8 3d a9 78 e1 8b 4c 24 04 8b 04 24 31
[  183.292470] RSP: 0018:ffffa9d4433b7ad0 EFLAGS: 00010246
[  183.293700] RAX: 0000000000000000 RBX: ffff8fe02cdad278 RCX: 0000000000000000
[  183.295363] RDX: 0000000000000000 RSI: ffff8fe02fa96a08 RDI: ffffffffc0793918
[  183.297039] RBP: 0000000000000001 R08: 000000000000efaa R09: 0000000000000039
[  183.298698] R10: 0000000000000000 R11: ffffa9d4433b7980 R12: 0000000000000000
[  183.300369] R13: ffff8fe01c09b000 R14: ffffffffc0789370 R15: ffff8fe017c65180
[  183.302051] FS:  00007f248349f540(0000) GS:ffff8fe02fa80000(0000) knlGS:0000000000000000
[  183.303927] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[  183.305284] CR2: 000055a40a927888 CR3: 0000000424786004 CR4: 0000000000160ee0
[  183.306953] Call Trace:
[  183.307554]  ? kmem_cache_alloc_trace+0x140/0x1c0
[  183.308681]  jdds_fs_map_buf_alloc.cold.21+0x1f/0xfb [jdds]
[  183.309990]  __find_jdds_buf+0x85/0x1c0 [jdds]
[  183.311056]  __find_and_get_jdds_map_buf+0x33/0xf0 [jdds]
[  183.312327]  get_jdds_map_buf_array+0xa0/0x110 [jdds]
[  183.313512]  ? blk_mq_try_issue_directly+0xb0/0xb0
[  183.314649]  handle_cow_write_operation+0x92/0x2e0 [jdds]
[  183.315932]  jdds_cow_bio_callback+0x60/0x90 [jdds]
[  183.317092]  jdds_bio_intercept_make_request+0x10c/0x170 [jdds]
[  183.318474]  generic_make_request+0xcf/0x310
[  183.319494]  ? bvec_alloc+0x51/0xe0
[  183.320332]  submit_bio+0x45/0x140
[  183.321145]  ? bio_add_page+0x42/0x50
[  183.322139]  _xfs_buf_ioapply+0x2dc/0x470 [xfs]
[  183.323252]  ? xlog_bdstrat+0x30/0x60 [xfs]
[  183.324265]  __xfs_buf_submit+0x67/0x230 [xfs]
[  183.325323]  xlog_bdstrat+0x30/0x60 [xfs]
[  183.326293]  xlog_sync+0x2b9/0x3a0 [xfs]
[  183.327241]  xfs_log_force+0x23c/0x2e0 [xfs]
[  183.328250]  ? __ia32_sys_fdatasync+0x20/0x20
[  183.329294]  xfs_fs_sync_fs+0x21/0x50 [xfs]
[  183.330288]  iterate_supers+0x98/0x100
[  183.331176]  ksys_sync+0x60/0xb0
[  183.331930]  __ia32_sys_sync+0xa/0x10
[  183.332802]  do_syscall_64+0x5b/0x1a0
```


## 其他信息
```
[ 1405.259870] jdds: ========== Super Block Info ==========
[ 1405.261111] jdds: file_magic:              0xbebaedfe
[ 1405.262292] jdds: l1t_offset:              67108864
[ 1405.263439] jdds: logical_block_size:      33554432
[ 1405.264578] jdds: physical_block_size:     0
[ 1405.265578] jdds: p2l_scale:               67108864
[ 1405.266714] jdds: block_count:             4163371008
[ 1405.267890] jdds: l1_table_entry_possible: 83886080
[ 1405.269026] jdds: l1_table_blocks:         3945070592
[ 1405.270201] jdds: l1_table_entry:          0
[ 1405.271173] jdds: blocks_per_l1:           0
[ 1405.272182] jdds: entries_per_l1:          0
[ 1405.273187] jdds: l2_table_blocks:         0
[ 1405.274188] jdds: l2_table_entry:          0
[ 1405.275191] jdds: blocks_per_l2:           0
[ 1405.276192] jdds: entries_per_l2:          0
[ 1405.277194] jdds: bitmap_offset:           0
[ 1405.278190] jdds: bitmap_entry_count:      0
[ 1405.279184] jdds: bitmap_blocks:           0
[ 1405.280185] jdds: max_size:                0
[ 1405.281186] jdds: next_block:              0
[ 1405.282188] jdds: ==========================================
```

Project: [[分区快照jdds|分区快照jdds]]