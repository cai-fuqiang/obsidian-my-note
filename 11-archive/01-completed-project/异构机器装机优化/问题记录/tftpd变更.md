# 2026-08-18-2030-tftp 变更timeout 1m
变更节点: `11.185.10.226`

变更步骤:
```
yum install tftp-server-5.2-22.el7.centos.sendfiletmo.x86_64.rpm -y
systemctl restart tftp
```

验证:
在 `11.185.10.226` 测试tftp功能
```
[root@A03-R28-I10-226-126P5JJ wfq]# tftp 11.185.10.226
tftp> get menu.c32
tftp> quit
[root@A03-R28-I10-226-126P5JJ wfq]# ls menu.c32
menu.c32
```
功能正常

# 2026-0819-1144-tftp 变更timeout 10m
变更节点: `11.185.10.226`
变更步骤:
```
yum install tftp-server-5.2-22.el7.centos.sendfiletmo_10m.x86_64.rpm
systemctl restart tftp
```

# 2026-0820-1055-tftp  会退tftp 到tftp-server-5.2-13
变更节点: `11.185.10.226`a

# 2026-0821-0605-tftp 启动tftpd

节点上tftpd不知道为什么退了。

```
[root@A27-R58-I79-211-0439471 ~]# systemctl status tftp
● tftp.service - Tftp Server
   Loaded: loaded (/usr/lib/systemd/system/tftp.service; indirect; vendor preset: disabled)
   Active: inactive (dead)
     Docs: man:in.tftpd
[root@A27-R58-I79-211-0439471 ~]# systemctl restart tftp
[root@A27-R58-I79-211-0439471 ~]# systemctl status tftp
● tftp.service - Tftp Server
   Loaded: loaded (/usr/lib/systemd/system/tftp.service; indirect; vendor preset: disabled)
   Active: active (running) since Fri 2026-08-21 17:45:51 CST; 2s ago
     Docs: man:in.tftpd
 Main PID: 50715 (in.tftpd)
   CGroup: /system.slice/tftp.service
           └─50715 /usr/sbin/in.tftpd -s /var/lib/tftpboot
```