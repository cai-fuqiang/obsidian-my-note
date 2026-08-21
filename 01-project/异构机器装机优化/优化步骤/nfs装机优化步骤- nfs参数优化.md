---
share_link: https://share.note.sx/myu5vmcc#ACeiZMZ4cQljgRvw8ffnpw
share_updated: 2026-08-17T11:43:27+08:00
---
1. 开启nfsd多线程为64
```
echo 64 > /proc/fs/nfsd/threads
```
2. 修改export `sync -> async`,e.g.
```
/srv/nfs/rootfs *(rw,sync,no_subtree_check,no_root_squash)
```

3. 修改`nfs.conf`让线程数永久生效
```
## /etc/nfs.conf
[nfsd]
  threads=64
```
3. 执行 `exportfs -arv` 让配置永久生效

后续打算， 修改pxe kernel cmdline 让其使用tcp
```
root=/dev/nfs nfsroot=192.168.1.100:/srv/nfs/rootfs,v3,tcp,hard,timeo=10,retrans=10
```

修改验证后，生效:
![[Pasted image 20260817100227.png]]

但是发现，无论是明确不明确指定tcp, v3，启动后均会使用tcp+v3(所以该步骤不必须)
![[Pasted image 20260817100626.png]]

