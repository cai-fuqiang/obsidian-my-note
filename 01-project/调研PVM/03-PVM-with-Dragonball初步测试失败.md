---
share_link: https://share.note.sx/j2hu253r#btxIN1OnumnLrznOdOeo2A
share_updated: 2026-08-20T13:59:21+08:00
---
# 使用dbs-cli启动

## dbs-cli: dragonball 默认内核 + nested kvm
```
/root/dbs-cli create   \
	--kernel-path \
		/opt/kata/share/kata-containers/vmlinux-dragonball-experimental.container   \
	--rootfs /opt/kata/share/kata-containers/kata-containers.img   \
	--mem-size 2048   \
	--vcpu 1   \
	--max-vcpu 1   \
	--serial-path stdio   \
	--boot-args \
	'console=ttyS0 earlyprintk=serial,ttyS0,115200 reboot=k panic=1 root=/dev/vda1 rootfstype=ext4'
```

guest 内核可以正常启动:
```
Warning: api server is not created because --api-sock-path is not provided when creating VM. Update command is not supported.
[    0.000000] Linux version 6.18.35 (@7182c7ffe72b) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #1 SMP Sat Jul 18 15:27:09 UTC 2026
[    0.000000] Command line: console=ttyS0 earlyprintk=serial,ttyS0,115200 reboot=k panic=1 root=/dev/vda1 rootfstype=ext4 virtio_mmio.device=8K@0xc0000000:5
[    0.000000] BIOS-provided physical RAM map:
```

## dbs-cli: PVM 内核 + (L1) kvm-pvm
命令行参数:
将上面命令中`--kernel-path`参数替换为PVM内核路径。

> [!important]  dragonball 不支持 vmlinuz(bzImage), 所以需要使用vmlinux 未压缩的文件。

> [!failure] 在测试前, 应手动加载`kvm-pvm`模块:
> ```
> modprobe -r kvm-intel
> modprobe kvm-pvm
> ```

测试结果, `dbs-cli` 进程立即返回，dmesg 报告 [[03-PVM-with-Dragonball初步测试失败#附录1 dragonball + PVM dmesg报错| 附录1]] 中的错误
# 使用kata测试

# 准备kata + dragonball环境
1. 使用`dragonball`文件覆盖`/etc/kata-containers/configuration.toml`
```
cp /opt/kata/share/defaults/kata-containers/runtime-rs/configuration-dragonball.toml  /etc/kata-containers/configuration.toml

```
2. 配置`/usr/local/bin/containerd-shim-kata-v2`
```diff
--- /usr/local/bin/containerd-shim-kata-v2.bak.20260813-061217
+++ /usr/local/bin/containerd-shim-kata-v2
@@ -1,3 +1,3 @@
 #!/bin/bash
-# QEMU (Default VMM)
-KATA_CONF_FILE=/opt/kata/share/defaults/kata-containers/configuration.toml /opt/kata/bin/containerd-shim-kata-v2 $@
+# Dragonball via Kata runtime-rs
+KATA_CONF_FILE=/etc/kata-containers/runtime-rs/configuration.toml exec /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 "$@"
```
3. 配置`/etc/containerd/config.toml`, 增加
```toml
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata-dragonball]
  runtime_type = "io.containerd.kata.v2"
  runtime_path = "/opt/kata/runtime-rs/bin/containerd-shim-kata-v2"
  [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata-dragonball.options]
    ConfigPath = "/etc/kata-containers/runtime-rs/configuration.toml"
```

## kata: dragonball 默认内核 + nested kvm

`/etc/kata-containers/configuration.toml`中 kernel 配置为:
```
kernel = "/opt/kata/share/kata-containers/vmlinux-dragonball-experimental.container"
```

执行:
```
nerdctl -n default run --rm --net=none \
	--runtime io.containerd.kata.v2 docker.1ms.run/library/busybox:latest \
	sh -c 'uname -r; cat /proc/cmdline'
```
会有一些报错。但是通过`journalctl -u containerd`, 发现guest内核已经成功启动:
```
Aug 13 07:18:26 localhost.localdomain kata[6547]: [    0.000000] Linux version 6.18.35 (@7182c7ffe72b) (gcc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #1 SMP Sat Jul 18 15:>
Aug 13 07:18:26 localhost.localdomain kata[6547]: [    0.000000] Command line: reboot=k panic=1 systemd.unit=kata-containers.target systemd.mask=systemd-networkd.service systemd.mask=systemd-networkd.socket ro>
Aug 13 07:18:26 localhost.localdomain kata[6547]: [    0.000000] BIOS-provided physical RAM map:
```

## kata:  PVM 内核 + (L1) kvm-pvm

将`/etc/kata-containers/configuration.toml`中 kernel 配置为:
```
kernel = "/linux-stable/vmlinux"
```

> [!error]  同样报告 [[03-PVM-with-Dragonball初步测试失败#附录1 dragonball + PVM dmesg报错| 附录1]]  中的错误

# 结论

> [!bug]  `dragonball + PVM` 会报告和 [[cloud-hypervisor 启动PVM虚拟机报错|cloud-hypervisor]] 相同的错误。

# 附录
## 附录1: dragonball + PVM dmesg报错
```
[ 1758.174218] WARNING: CPU: 26 PID: 4025 at arch/x86/kvm/../../../virt/kvm/pfncache.c:298 __kvm_gpc_refresh+0x41c/0x430 [kvm]
...
[ 1758.174389] Call Trace:
[ 1758.174392]  <TASK>
[ 1758.174395]  kvm_gpc_refresh+0x4a/0x80 [kvm]
[ 1758.174444]  pvm_get_vcpu_struct+0x34/0x70 [kvm_pvm]
[ 1758.174449]  __do_pvm_event+0x22/0x310 [kvm_pvm]
[ 1758.174452]  pvm_inject_exception+0x42/0x70 [kvm_pvm]
[ 1758.174456]  kvm_check_and_inject_events+0x241/0x4a0 [kvm]
[ 1758.174514]  kvm_arch_vcpu_ioctl_run+0xbdf/0x1720 [kvm]
[ 1758.174572]  kvm_vcpu_ioctl+0x2ed/0x810 [kvm]
[ 1758.174616]  ? rcu_core+0x181/0xa50
[ 1758.174622]  ? enqueue_hrtimer+0x30/0x80
[ 1758.174626]  ? __hrtimer_run_queues+0x13b/0x2a0
[ 1758.174628]  ? kvm_clock_get_cycles+0x18/0x30
[ 1758.174633]  ? ktime_get+0x36/0xc0
[ 1758.174636]  ? lapic_next_deadline+0x27/0x30
[ 1758.174642]  __x64_sys_ioctl+0x8f/0xc0
[ 1758.174647]  do_syscall_64+0x4f/0x120
[ 1758.174654]  entry_SYSCALL_64_after_hwframe+0x76/0x7e
```

# 附录2: guest lscpu
```
[root@general-2-loongson-11-211-129-66 ~]# lscpu
Architecture:          loongarch64
  CPU op-mode(s):      32-bit, 64-bit
  Address sizes:       47 bits physical, 48 bits virtual
  Byte Order:          Little Endian
CPU(s):                4
  On-line CPU(s) list: 0-3
BIOS Vendor ID:        QEMU
Model name:            Loongson-3A5000
  BIOS Model name:     virt  CPU @ 2.0GHz
  BIOS CPU family:     1
  CPU family:          Loongson-64bit
  Model:               0x10
  Thread(s) per core:  1
  Core(s) per socket:  1
  Socket(s):           4
  BogoMIPS:            4000.00
  Flags:               cpucfg lam ual fpu lsx lasx crc32 ptw lbt_x86 lbt_arm lbt_mips
Caches (sum of all):
  L1d:                 256 KiB (4 instances)
  L1i:                 256 KiB (4 instances)
  L2:                  1 MiB (4 instances)
  L3:                  16 MiB (1 instance)
NUMA:
  NUMA node(s):        1
  NUMA node0 CPU(s):   0-3
```
# 参考链接
1. [Can Dragonball be used as an external VM like QEMU?](https://github.com/kata-containers/kata-containers/issues/10359)
2. [github : dbs-cli](https://github.com/openanolis/dbs-cli)
3. [Kata3.0.0 x LifseaOS x 龙蜥内核三管齐下！带你体验最新的安全容器之旅](https://developer.aliyun.com/article/1084746)
4. [LifseaOS 悄然来袭，一款为云原生而生的 OS](https://developer.aliyun.com/article/809946)
