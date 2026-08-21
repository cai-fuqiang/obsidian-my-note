---
data: 2026-08-14
问题分类: cbd-symlink-delete
是否定位成功: true
目前结论: cbd软连接被删除
is_issue: true
instance: i-hqfklgby3s
share_link: https://share.note.sx/xi0gb05c#8vmNP2mQ1Ef2Xj3Vv8QLEw
share_updated: 2026-08-20T16:20:48+08:00
---
# 问题现象

虚拟机串口日志打印io error, 随后部分进程产生coredump， 因 `binfmt-0000`模块加载失败而失败
```
[78798.407648][    C3] I/O error, dev vdb, sector 18391904 op 0x0:(READ) flags 0x800 phys_seg 1 prio class 2
...
[78798.705134][    C2] I/O error, dev vda, sector 42486200 op 0x1:(WRITE) flags 0x9800 phys_seg 18 prio class 2
[78798.706257][  T466] Aborting journal on device vda2-8.
[78798.707825][    C0] I/O error, dev vda, sector 42205184 op 0x1:(WRITE) flags 0x9800 phys_seg 1 prio class 2
[78798.709089][    C0] Buffer I/O error on dev vda2, logical block 4751360, lost sync page write
[78798.709309][  T578] EXT4-fs error (device vda2): ext4_journal_check_start:84: comm systemd-journal: Detected aborted journal
[78798.710099][  T466] JBD2: I/O error when updating journal superblock for vda2-8.
[78798.712739][    C1] Buffer I/O error on dev vda2, logical block 0, lost sync page write
[78798.714000][  T578] EXT4-fs (vda2): I/O error while writing superblock
[78798.715332][  T914] EXT4-fs error (device vda2): ext4_journal_check_start:84: comm nginx: Detected aborted journal
[78798.716431][  T578] EXT4-fs (vda2): Remounting filesystem read-only
[78798.717740][    C3] Buffer I/O error on dev vda2, logical block 0, lost sync page write
[78798.719799][  T914] EXT4-fs (vda2): I/O error while writing superblock
[78803.680226][T102342] request_module: modprobe binfmt-0000 cannot be processed, kmod busy with 50 threads for more than 5 seconds now
[78803.691108][T54285] Core dump to |/usr/lib/systemd/systemd-coredump pipe failed
[78808.800195][T102399] request_module: modprobe binfmt-0000 cannot be processed, kmod busy with 50 threads for more than 5 seconds now
```

qemu log 中报告io error:
```
{"timestamp": {"seconds": 1786673980, "microseconds": 604261}, "event": "BLOCK_IO_ERROR", "data": {"device": "", "node-name": "libvirt-4-format", "reason": "No space left on device", "operation": "write", "action": "report"}}
{"timestamp": {"seconds": 1786673985, "microseconds": 676637}, "event": "BLOCK_IO_ERROR", "data": {"device": "", "node-name": "libvirt-4-format", "reason": "No space left on device", "operation": "write", "action": "report"}}
```

查看云盘是否还能使用:
```
[root@11-211-129-66 qemu]# for LINK in $(virsh dumpxml i-hqfklgby3s | grep run | awk '{print $2}' | cut -d "'" -f2); do ls $LINK; done
ls: cannot access '/run/ebs/softlink/nbd_vol-166va96qjq_i-hqfklgby3s': No such file or directory
ls: cannot access '/run/ebs/softlink/nbd_vol-x17a9so79o_i-hqfklgby3s': No such file or directory
ls: cannot access '/run/ebs/softlink/nbd_vol-c3epyhjeic_i-hqfklgby3s': No such file or directory
ls: cannot access '/run/ebs/softlink/nbd_vol-khchc1rfd1_i-hqfklgby3s': No such file or directory
```

可以发现这些 nbd文件被删除. host 内核打印:
```
[106318.993305] ------------[ cut here ]------------
[106318.999287] WARNING: CPU: 104 PID: 31741 at block/blk-core.c:225 blk_status_to_errno+0x30/0x40
[106319.009276] Modules linked in: nft_limit xt_limit veth openvswitch nf_conncount vfio_pci vfio_pci_core irqbypass vfio_iommu_type1 vfio xt_CHECKSUM xt_MASQUERADE xt_conntrack ipt_REJECT nf_reject_ipv4 nft_compat nft_chain_nat nf_nat nf_conntrack nf_defrag_ipv6 nf_defrag_ipv4 nf_tables bridge 8021q garp mrp stp llc tun rfkill cbd(OE) nls_cp936 vfat fat ipmi_ssif acpi_ipmi snd_hda_intel snd_intel_dspcfg snd_hda_codec kvm snd_hda_core snd_hwdep ipmi_si snd_pcm cdc_ether ipmi_devintf efi_pstore usbnet pstore rtc_efi snd_timer ses loongarch_iommu ipmi_msghandler enclosure i2c_ls2x sg fuse nfnetlink rpcrdma rdma_ucm ib_srpt ib_isert iscsi_target_mod target_core_mod ib_iser libiscsi scsi_transport_iscsi rdma_cm ib_umad iw_cm ib_ipoib ib_cm mlx5_ib ib_uverbs ib_core sd_mod t10_pi crc64_rocksoft_generic crc64_rocksoft crc64 mlx5_core megaraid_sas r8169 mlxfw psample realtek dm_mirror dm_region_hash dm_log dm_multipath dm_mod ipv6 crc_ccitt
[106319.097080] CPU: 104 PID: 31741 Comm: cbs-agent Kdump: loaded Tainted: G           OE       6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64 #1
[106319.111900] Hardware name:  /, BIOS
[106319.116910] pc 9000000000b88540 ra 9000000000b803c4 tp 900020149f8e8000 sp 900020149f8ebc10
[106319.126631] a0 00000000000000fb a1 9000001524bc4540 a2 0000000000002000 a3 900000000b804000
[106319.136381] a4 900000000b803ff8 a5 900020149f8ebae0 a6 0000000000000001 a7 0000000000000001
[106319.146151] t0 00000000000000fb t1 0000000000000012 t2 ffffffffffff2e02 t3 0000000000000003
[106319.155917] t4 fffffffffffffffe t5 0000000000000000 t6 0000000000000000 t7 0000000000000000
[106319.165637] t8 0000000000000001 u0 0088fbc30e4b9639 s9 000000c000537a40 s0 9000001524bc4540
[106319.175362] s1 90000015223b6400 s2 00000000000000fb s3 000000000000000d s4 000000000000000a
[106319.185120] s5 0000000000002000 s6 900000157f7e1c80 s7 0000000000000000 s8 ffff80002068b390
[106319.194894]    ra: 9000000000b803c4 blkdev_bio_end_io_async+0xdc/0xe8
[106319.202770]   ERA: 9000000000b88540 blk_status_to_errno+0x30/0x40
[106319.210270]  CRMD: 000000b0 (PLV0 -IE -DA +PG DACF=CC DACM=CC -WE)
[106319.217849]  PRMD: 00000000 (PPLV0 -PIE -PWE)
[106319.223583]  EUEN: 00000000 (-FPE -SXE -ASXE -BTE)
[106319.229776]  ECFG: 00071c1d (LIE=0,2-4,10-12 VS=7)
[106319.235963] ESTAT: 000c1800 [BRK] (IS=11-12 ECode=12 EsubCode=0)
[106319.243286]  PRID: 0014d011 (Loongson-64bit, Loongson-3C6000/D)
[106319.250505] CPU: 104 PID: 31741 Comm: cbs-agent Kdump: loaded Tainted: G           OE       6.6.0-jdcloud1243892.0.0fd19ac62064c.loongarch64 #1
[106319.265241] Hardware name:  /, BIOS
[106319.270285] Stack : 0000000000000000 0000000000000000 90000000002248d4 900020149f8e8000
[106319.279771]         900020149f8eb860 900020149f8eb868 0000000000000000 900020149f8eb9a8
[106319.289098]         900020149f8eb9a0 900020149f8eb9a0 900020149f8eb790 0000000000000001
[106319.298438]         0000000000000001 900020149f8eb868 6b88fbc30e4b9639 90003000856fecc0
[106319.307774]         900020149f8eb688 fffffffffffffffe 0000000000000000 0000000000000000
[106319.317098]         0000000000000000 0000000000000001 000030007f0e8000 000000c000537a40
[106319.326425]         0000000000000000 0000000000000000 9000000001b04180 90000000023b5000
[106319.335750]         9000000000b88540 00000000000000e1 900000157f7e1c80 0000000000000000
[106319.345127]         ffff80002068b390 0000000000000000 90000000002248ec 000000c00080c000
[106319.354651]         00000000000000b0 0000000000000000 0000000000000000 0000000000071c1d
[106319.363992]         ...
[106319.367775] Call Trace:
[106319.367780] [<90000000002248ec>] show_stack+0x64/0x188
[106319.377927] [<90000000015cffac>] dump_stack_lvl+0x5c/0x88
[106319.384654] [<900000000024f0e0>] __warn+0x88/0x148
[106319.390771] [<900000000155ca08>] report_bug+0x218/0x2d8
[106319.397265] [<90000000015d09f0>] do_bp+0x258/0x3e0
[106319.403327] [<9000000000222b70>] _handle_bp+0x134/0x204
[106319.409804] [<9000000000b88540>] blk_status_to_errno+0x30/0x40
[106319.416844] [<9000000000b803c0>] blkdev_bio_end_io_async+0xd8/0xe8
[106319.424220] [<9000000000b9c324>] blk_update_request+0x20c/0x570
[106319.431348] [<9000000000b9ee84>] blk_mq_end_request+0x24/0x3c0
[106319.438406] [<ffff800002e6a414>] _abort_dev_cmds+0x1ec/0x348 [cbd]
[106319.445889] [<ffff800002e6d198>] cbd_delete_dev+0x300/0x6a0 [cbd]
[106319.453178] [<ffff800002e6e49c>] cbd_misc_ioctl+0x10c/0x468 [cbd]
[106319.460460] [<90000000005fcf38>] sys_ioctl+0xc8/0x150
[106319.466642] [<90000000015d1408>] do_syscall+0x88/0xd0
[106319.472910] [<9000000000221f54>] handle_syscall+0xd4/0x190

[106319.482193] ---[ end trace 0000000000000000 ]---
```


dmesg 打印 cbd warn时间点
```
[Thu Aug 13 20:07:54 2026] ------------[ cut here ]------------
[Thu Aug 13 20:07:54 2026] WARNING: CPU: 104 PID: 31741 at block/blk-core.c:225 blk_status_to_errno+0x30/0x40
```

> [!summary] 黄老板反应有云盘卸载时间点为: `2026-08-13 20:07:45`, 所以是云盘卸载导致的IO 错误