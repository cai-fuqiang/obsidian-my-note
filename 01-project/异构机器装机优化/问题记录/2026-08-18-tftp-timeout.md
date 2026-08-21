---
share_link: https://share.note.sx/8fbbt99b#YluVt69ZJazEC3Y1c5IurQ
share_updated: 2026-08-18T18:16:37+08:00
---
# timeout日志

在tftp server 遇到了timeout的一些日志

 一个ip的大概信息为:
```
 Aug 18 13:44:20 A03-R28-I10-226-126P5JJ dhcpd: DHCPOFFER on 11.199.34.23 to 08:20:e7:26:df:9c via 11.199.33.240
Aug 18 13:44:23 A03-R28-I10-226-126P5JJ dhcpd: DHCPREQUEST for 11.199.34.23 (11.185.10.226) from 08:20:e7:26:df:9c via 11.199.33.240
Aug 18 13:44:23 A03-R28-I10-226-126P5JJ dhcpd: DHCPACK on 11.199.34.23 to 08:20:e7:26:df:9c via 11.199.33.240
Aug 18 13:44:24 A03-R28-I10-226-126P5JJ in.tftpd[48542]: Client 11.199.34.23 finished ubuntu-nfs-common/BOOTX64.EFI
Aug 18 13:44:24 A03-R28-I10-226-126P5JJ in.tftpd[48543]: Client 11.199.34.23 finished ubuntu-nfs-common/revocations.efi
Aug 18 13:44:25 A03-R28-I10-226-126P5JJ in.tftpd[48544]: Client 11.199.34.23 finished ubuntu-nfs-common/grubx64.efi
Aug 18 13:44:25 A03-R28-I10-226-126P5JJ in.tftpd[48560]: Client 11.199.34.23 finished /grub/grub.cfg
Aug 18 13:44:25 A03-R28-I10-226-126P5JJ in.tftpd[48561]: Client 11.199.34.23 finished ubuntu-nfs-common/grub.cfg-08:20:e7:26:df:9c
Aug 18 13:44:33 A03-R28-I10-226-126P5JJ in.tftpd[48579]: Client 11.199.34.23 finished ubuntu-nfs-common/vmlinuz
Aug 18 13:44:40 A03-R28-I10-226-126P5JJ in.tftpd[48719]: Client 11.199.34.23 finished ubuntu-nfs-common/initrd.zst
Aug 18 13:44:40 A03-R28-I10-226-126P5JJ in.tftpd[48719]: Client 11.199.34.23 timed out
```
在传递完`initrd.zst`后，紧接着又报告timeout 错误.
 
所有timeout 过滤如下
```
Aug 18 13:44:07 A03-R28-I10-226-126P5JJ in.tftpd[48182]: Client 11.185.10.226 timed out
Aug 18 13:44:40 A03-R28-I10-226-126P5JJ in.tftpd[48719]: Client 11.199.34.23 timed out
Aug 18 13:44:52 A03-R28-I10-226-126P5JJ in.tftpd[48350]: Client 11.199.34.22 timed out
Aug 18 13:45:01 A03-R28-I10-226-126P5JJ in.tftpd[48714]: Client 11.199.39.175 timed out
Aug 18 13:45:07 A03-R28-I10-226-126P5JJ in.tftpd[49118]: Client 11.199.39.23 timed out
Aug 18 13:45:12 A03-R28-I10-226-126P5JJ in.tftpd[48708]: Client 11.199.39.170 timed out
Aug 18 13:45:16 A03-R28-I10-226-126P5JJ in.tftpd[49032]: Client 11.199.39.200 timed out
Aug 18 13:45:27 A03-R28-I10-226-126P5JJ in.tftpd[48707]: Client 11.199.34.28 timed out
Aug 18 13:45:45 A03-R28-I10-226-126P5JJ in.tftpd[49264]: Client 11.199.39.21 timed out
Aug 18 13:57:48 A03-R28-I10-226-126P5JJ in.tftpd[57136]: Client 11.199.39.205 timed out
Aug 18 13:57:55 A03-R28-I10-226-126P5JJ in.tftpd[57281]: Client 11.199.34.26 timed out
Aug 18 13:58:04 A03-R28-I10-226-126P5JJ in.tftpd[57441]: Client 11.199.39.199 timed out
Aug 18 13:58:07 A03-R28-I10-226-126P5JJ in.tftpd[57384]: Client 11.199.34.10 timed out
Aug 18 13:58:09 A03-R28-I10-226-126P5JJ in.tftpd[57134]: Client 11.199.34.72 timed out
Aug 18 13:58:20 A03-R28-I10-226-126P5JJ in.tftpd[57542]: Client 11.199.39.217 timed out
Aug 18 13:58:20 A03-R28-I10-226-126P5JJ in.tftpd[57139]: Client 11.199.34.8 timed out
Aug 18 13:58:23 A03-R28-I10-226-126P5JJ in.tftpd[57283]: Client 11.199.34.74 timed out
Aug 18 13:58:26 A03-R28-I10-226-126P5JJ in.tftpd[57370]: Client 11.199.39.206 timed out
Aug 18 13:58:26 A03-R28-I10-226-126P5JJ in.tftpd[57130]: Client 11.199.34.44 timed out
Aug 18 17:11:07 A03-R28-I10-226-126P5JJ in.tftpd[133412]: Client 11.199.34.68 timed out
Aug 18 17:11:32 A03-R28-I10-226-126P5JJ in.tftpd[133714]: Client 11.199.34.9 timed out
Aug 18 17:12:56 A03-R28-I10-226-126P5JJ in.tftpd[134733]: Client 11.199.39.28 timed out
```

# 对比创建失败的机器和所有timeout机器
* 所有创建失败的机器ip 我们放到a.txt文件
* timeout机器我们在 /var/log/message 中过滤

执行下面命令进行对比:
```sh
# 将message中tftp timeout相关机器ip进行排序，存放到b.txt
[root@A03-R28-I10-226-126P5JJ wfq]# cat /var/log/messages |grep timed |grep 'Aug 18' |grep '13:' |awk '{print $7}' |sort  > b.txt
# 排序a.txt > aa.txt
[root@A03-R28-I10-226-126P5JJ wfq]# cat a.txt |sort > aa.txt
[root@A03-R28-I10-226-126P5JJ wfq]# diff -Naru aa.txt b.txt
--- aa.txt      2026-08-18 17:54:14.397429949 +0800
+++ b.txt       2026-08-18 17:53:16.992951307 +0800
@@ -1,11 +1,10 @@
+11.185.10.226
 11.199.34.10
 11.199.34.22
 11.199.34.23
 11.199.34.26
 11.199.34.28
 11.199.34.44
-11.199.34.67
-11.199.34.7
 11.199.34.72
 11.199.34.74
 11.199.34.8
```
* 11.199.34.67
大部分可以重合,其中有两台机器装机失败
![[Pasted image 20260818175919.png]]

这个机器已经 走完了initramfs的加载走到了后面的流程。
* 11.199.34.7
![[Pasted image 20260818180049.png]]

这个机器比较奇怪，我们完整拉下这个机器的ip的日志:
```
[root@A03-R28-I10-226-126P5JJ wfq]# cat /var/log/messages |grep  '11.199.34.7 '
Aug 18 13:57:19 A03-R28-I10-226-126P5JJ dhcpd: DHCPOFFER on 11.199.34.7 to 2c:9d:90:ff:62:d0 via 11.199.33.240
Aug 18 13:57:22 A03-R28-I10-226-126P5JJ dhcpd: DHCPREQUEST for 11.199.34.7 (11.185.10.226) from 2c:9d:90:ff:62:d0 via 11.199.33.240
Aug 18 13:57:22 A03-R28-I10-226-126P5JJ dhcpd: DHCPACK on 11.199.34.7 to 2c:9d:90:ff:62:d0 via 11.199.33.240
Aug 18 13:57:23 A03-R28-I10-226-126P5JJ in.tftpd[56974]: Client 11.199.34.7 finished ubuntu-nfs-common/BOOTX64.EFI
Aug 18 13:57:23 A03-R28-I10-226-126P5JJ in.tftpd[56975]: Client 11.199.34.7 finished ubuntu-nfs-common/revocations.efi
Aug 18 13:57:24 A03-R28-I10-226-126P5JJ in.tftpd[56976]: Client 11.199.34.7 finished ubuntu-nfs-common/grubx64.efi
Aug 18 13:57:24 A03-R28-I10-226-126P5JJ in.tftpd[56989]: Client 11.199.34.7 finished /grub/grub.cfg
Aug 18 13:57:24 A03-R28-I10-226-126P5JJ in.tftpd[56990]: Client 11.199.34.7 finished ubuntu-nfs-common/grub.cfg-2c:9d:90:ff:62:d0
```
可以发现这个机器还没有拉`kernel`和`initramfs`
# 暂时结论

> [!summary] 
> 1. 启动失败卡在kernel 早期5s位置，基本上和tftp timedout有关系。（大部分机器)
> 2. 如果卡在grub，则说明client 还没有下载kernel和initramfs，估计也和tftp有关，但是日志中没有打印
> 3. 少部分机器卡在启动后期，mlnx网卡报错。原因位置


# 走读tftpd 代码
```

```

# 附录
正常启动完整日志 ：
```
Aug 18 18:03:54 A03-R28-I10-226-126P5JJ dhcpd: DHCPOFFER on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:03:58 A03-R28-I10-226-126P5JJ dhcpd: DHCPREQUEST for 11.199.34.72 (11.185.10.226) from f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:03:58 A03-R28-I10-226-126P5JJ dhcpd: DHCPACK on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:03:58 A03-R28-I10-226-126P5JJ xinetd[97007]: START: tftp pid=13437 from=11.199.34.72
Aug 18 18:03:59 A03-R28-I10-226-126P5JJ in.tftpd[13444]: Client 11.199.34.72 finished ubuntu-nfs-common/BOOTX64.EFI
Aug 18 18:03:59 A03-R28-I10-226-126P5JJ in.tftpd[13453]: Client 11.199.34.72 finished ubuntu-nfs-common/revocations.efi
Aug 18 18:04:00 A03-R28-I10-226-126P5JJ in.tftpd[13454]: Client 11.199.34.72 finished ubuntu-nfs-common/grubx64.efi
Aug 18 18:04:00 A03-R28-I10-226-126P5JJ in.tftpd[13479]: Client 11.199.34.72 finished /grub/grub.cfg
Aug 18 18:04:00 A03-R28-I10-226-126P5JJ in.tftpd[13480]: Client 11.199.34.72 finished ubuntu-nfs-common/grub.cfg-f0:bc:50:1a:ab:88
Aug 18 18:04:08 A03-R28-I10-226-126P5JJ in.tftpd[13517]: Client 11.199.34.72 finished ubuntu-nfs-common/vmlinuz
Aug 18 18:04:58 A03-R28-I10-226-126P5JJ in.tftpd[13566]: Client 11.199.34.72 finished ubuntu-nfs-common/initrd.zst
Aug 18 18:05:09 A03-R28-I10-226-126P5JJ dhcpd: DHCPOFFER on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:05:09 A03-R28-I10-226-126P5JJ dhcpd: DHCPREQUEST for 11.199.34.72 (11.185.10.226) from f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:05:09 A03-R28-I10-226-126P5JJ dhcpd: DHCPACK on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:05:09 A03-R28-I10-226-126P5JJ rpc.mountd[12770]: authenticated mount request from 11.199.34.72:825 for /srv/nfs/rootfs (/srv/nfs/rootfs)
Aug 18 18:09:05 A03-R28-I10-226-126P5JJ rpc.mountd[12770]: authenticated unmount request from 11.199.34.72:886 for /srv/nfs/rootfs/etc/logs (/srv/nfs/rootfs)
Aug 18 18:09:05 A03-R28-I10-226-126P5JJ rpc.mountd[12770]: authenticated unmount request from 11.199.34.72:885 for /srv/nfs/rootfs/etc/instance (/srv/nfs/rootfs)
Aug 18 18:10:15 A03-R28-I10-226-126P5JJ dhcpd: DHCPOFFER on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:10:18 A03-R28-I10-226-126P5JJ dhcpd: DHCPREQUEST for 11.199.34.72 (11.185.10.226) from f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:10:18 A03-R28-I10-226-126P5JJ dhcpd: DHCPACK on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:10:19 A03-R28-I10-226-126P5JJ in.tftpd[15605]: Client 11.199.34.72 finished ubuntu-nfs-common/BOOTX64.EFI
Aug 18 18:10:19 A03-R28-I10-226-126P5JJ in.tftpd[15610]: Client 11.199.34.72 finished ubuntu-nfs-common/revocations.efi
Aug 18 18:10:20 A03-R28-I10-226-126P5JJ in.tftpd[15612]: Client 11.199.34.72 finished ubuntu-nfs-common/grubx64.efi
Aug 18 18:10:20 A03-R28-I10-226-126P5JJ in.tftpd[15617]: Client 11.199.34.72 finished /grub/grub.cfg
Aug 18 18:10:20 A03-R28-I10-226-126P5JJ in.tftpd[15618]: Client 11.199.34.72 finished ubuntu-nfs-common/grub.cfg-f0:bc:50:1a:ab:88
Aug 18 18:10:28 A03-R28-I10-226-126P5JJ in.tftpd[15621]: Client 11.199.34.72 finished ubuntu-nfs-common/vmlinuz
Aug 18 18:11:19 A03-R28-I10-226-126P5JJ in.tftpd[15631]: Client 11.199.34.72 finished ubuntu-nfs-common/initrd.zst
Aug 18 18:11:30 A03-R28-I10-226-126P5JJ dhcpd: DHCPOFFER on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:11:30 A03-R28-I10-226-126P5JJ dhcpd: DHCPREQUEST for 11.199.34.72 (11.185.10.226) from f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:11:30 A03-R28-I10-226-126P5JJ dhcpd: DHCPACK on 11.199.34.72 to f0:bc:50:1a:ab:88 via 11.199.33.242
Aug 18 18:11:30 A03-R28-I10-226-126P5JJ rpc.mountd[12770]: authenticated mount request from 11.199.34.72:823 for /srv/nfs/rootfs (/srv/nfs/rootfs)
```