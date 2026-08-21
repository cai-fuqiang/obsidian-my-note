---
share_link: https://share.note.sx/4f1clbn7#nNDA4uyCITDwH/Da0Tkd1g
share_updated: 2026-08-17T13:18:01+08:00
---

## PXE、NFS和HTTP带宽保障

启动风暴期间，机器首先通过TFTP下载内核和initramfs，然后挂载NFS rootfs，最后通过Nginx下载装机镜像。目标不是固定限制某个服务，而是在链路拥塞时优先保证TFTP和NFS；服务空闲时，其带宽可以被其他服务全部借用。

相关脚本：

- [[limit-nginx-443-bandwidth.sh|变更脚本]]
- [[restore-nginx-443-bandwidth.sh|恢复脚本]]

### 带宽模型

默认比例：

```text
网卡总带宽
├── 80:30 TFTP/PXE：保证20%，优先级0，最高100%
├── 80:40 NFS/RPC： 保证20%，优先级1，最高100%
├── 80:10 HTTP/80： 保证50%，优先级2，最高100%
└── 80:20 其他流量：保证10%，优先级3，最高100%
```

HTB参数含义：

- `rate`：发生带宽竞争时保证的最低带宽。
- `ceil`：有空闲带宽时允许借用到的最高带宽。
- `prio`：借用空闲带宽的优先级，数字越小优先级越高。

所有class的 `ceil` 都等于网卡总带宽。因此TFTP不工作时，HTTP、NFS或其他任一活跃服务都可以借用空闲带宽并占满链路。只有发生竞争时，才按照 `rate` 保证各服务的最低带宽。

以25GbE为例：

```text
TFTP/PXE：rate 5000Mbit，ceil 25000Mbit
NFS/RPC： rate 5000Mbit，ceil 25000Mbit
HTTP/80： rate 12500Mbit，ceil 25000Mbit
其他流量：rate 2500Mbit，ceil 25000Mbit
```

保证带宽之和必须等于或小于父类总带宽：

```text
5000 + 5000 + 12500 + 2500 = 25000Mbit
```

### 执行方法

脚本需要显式指定网卡、总带宽和一个或多个PXE客户端网段：

```bash
sudo ./limit-nginx-443-bandwidth.sh \
    eth0 \
    25000 \
    11.214.98.0/24 \
    11.214.99.0/24
```

最多支持8个PXE客户端网段。生产环境显式指定带宽可以避免bond或虚拟网卡自动上报速率不准确。

脚本会检查：

- 使用root权限执行。
- 网卡和 `tc` 命令存在。
- 总带宽是有效整数。
- PXE客户端网段是有效IPv4 CIDR。
- 网卡当前没有自定义根QoS，避免覆盖已有规则。

变更前状态记录在：

```text
/run/nginx-https-bandwidth-limit/
```

### TFTP分类方式

TFTP客户端首先向服务端UDP/69发送请求，但服务端传输内核和initramfs时会使用动态UDP源端口：

```text
客户端随机端口 -> 服务端UDP/69       RRQ
服务端动态端口 -> 客户端随机端口      OACK/DATA
```

因此不能只匹配服务端源端口69。脚本通过“发往PXE客户端网段的IPv4 UDP流量”识别TFTP/PXE流量：

```bash
tc filter add dev eth0 protocol ip parent 80: prio 1 u32 \
    match ip protocol 17 0xff \
    match ip dst 11.214.98.0/24 \
    flowid 80:30
```

每个PXE网段使用一个独立优先级，从 `pref 1` 开始。该方式也会把发往PXE网段的其他UDP响应放入最高优先级类。

### Nginx和NFS分类

Nginx HTTP响应进入 `80:10`：

```bash
tc filter add dev eth0 protocol ip parent 80: prio 10 u32 \
    match ip protocol 6 0xff \
    match ip sport 80 0xffff \
    flowid 80:10
```

NFSv3关键TCP端口进入 `80:40`：

```bash
# NFS数据
tc filter add dev eth0 protocol ip parent 80: prio 20 u32 \
    match ip protocol 6 0xff \
    match ip sport 2049 0xffff \
    flowid 80:40

# rpcbind
tc filter add dev eth0 protocol ip parent 80: prio 21 u32 \
    match ip protocol 6 0xff \
    match ip sport 111 0xffff \
    flowid 80:40

# mountd
tc filter add dev eth0 protocol ip parent 80: prio 22 u32 \
    match ip protocol 6 0xff \
    match ip sport 20048 0xffff \
    flowid 80:40
```

未命中以上规则的流量通过 `default 20` 进入 `80:20`。

### 查看统计

查看class的累计字节、借用、丢包和积压：

```bash
tc -s -d class show dev eth0
tc -s -d qdisc show dev eth0
```

持续观察：

```bash
watch -n 1 'tc -s class show dev eth0'
```

重点关注：

- `80:30`：TFTP/PXE流量。
- `80:40`：NFS/RPC流量。
- `80:10`：Nginx TCP/80流量。
- `80:20`：未分类的其他流量。
- `borrowed`：该class正在借用其他服务的空闲带宽。
- `overlimits`：HTB正在执行带宽调度，不等于丢包。
- `dropped`：队列丢包数量。
- `backlog`：等待发送的数据量。

查看TFTP/PXE网段规则命中，以两个网段为例：

```bash
tc -s -d filter show dev eth0 parent 80: pref 1
tc -s -d filter show dev eth0 parent 80: pref 2
```

查看NFSv3阶段命中：

```bash
tc -s -d filter show dev eth0 parent 80: pref 20
tc -s -d filter show dev eth0 parent 80: pref 21
tc -s -d filter show dev eth0 parent 80: pref 22
```

### 预期行为

```text
只有HTTP运行：HTTP可以借用至网卡总带宽
只有TFTP运行：TFTP可以借用至网卡总带宽
只有NFS运行：NFS可以借用至网卡总带宽
全部服务繁忙：TFTP和NFS分别至少获得20%，并优先借用空闲带宽
```

### 恢复配置

```bash
sudo ./restore-nginx-443-bandwidth.sh eth0
```

恢复脚本确认根队列是本脚本创建的 `htb 80:` 后执行：

```bash
tc qdisc del dev eth0 root
```

删除根HTB会同时删除其class、filter和fq_codel子队列，并恢复网卡默认队列。

### 使用限制

- 当前规则只处理IPv4流量。
- TFTP/PXE规则按目标网段匹配所有UDP，不仅限于TFTP。
- NFS规则当前只覆盖TCP/111、TCP/20048和TCP/2049。
- `tc` 只能保障服务器出站队列，不能解决TFTP进程并发、磁盘IO、UDP socket缓冲区或交换机丢包。
- 脚本文件名保留旧名称以兼容已有使用方式，实际Nginx端口为TCP/80。
