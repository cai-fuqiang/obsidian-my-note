---
share_link: https://share.note.sx/62oei3mh#rNTwdxmbV4EdCWr4Hb9dBw
share_updated: 2026-08-20T13:59:13+08:00
---
# overflow

PVM概述:
* PVM 是专门用于 支持 没有 hardware virualization 场景下的  Kata Containers
* 它类似于KVM的一个vendor，类似于intel/AMD

本文主要来讲解 如何使用上层软件启动PVM 安全容器。

# pre-requeirsitis

* software require 
	* Kata Containers
	* Containerd

PVM需要修改host/guest kernels，目前提供了两个版本:
* 6.12.33: (如果需要使用该版本，需要将Kata Containers 升级到3.14 or later)
* 6.7.0-rc7
另外，如果仅用于验证, 可以使用PVM官方提供的 VM Image<sup>2</sup>

> [!note] 我们这里先使用 `openeuler-2403-sp3` 搭建Kata + PVM

# test PVM in openEuler-2403-sp3
## install kata containers

* install kata (4.0.0)
  > [!tip]  如果使用6.12内核，需要使用`3.14+`, 而原文中的示例是3.19.1，我们这里直接选择最新的, 
  
 ```
 wget https://github.com/kata-containers/kata-containers/releases/download/4.0.0/kata-static-4.0.0-amd64.tar.zst
 ```

   > [!note] kata-static 文件较大, 可以使用`bgithub.xyz`网站进行加速

* 解压到根目录: `sudo tar -C / -xvf kata-static-3.19.1-amd64.tar.xz`
* 为了让`Containerd` 能够找到kata的命令, 在bashrc中增加
 ```sh
 export PATH=${PATH}:/opt/kata/bin/
 ```

* kata runtime版本验证:
 ```sh
 [root@localhost ~]# kata-runtime --version
 kata-runtime  : 4.0.0
    commit   : cf82bb35c80320178bf7570252fe75d6fb263209
    OCI specs: 1.2.1
 
 ```

## install /config Containerd

### install containerd

* install Containerd(2.3.3) (我们这里也选择最新的)
```
wget https://github.com/containerd/containerd/releases/download/v2.3.3/containerd-2.3.3-linux-amd64.tar.gz
```
* 解压安装containerd: `tar -C /usr/local -xvf containerd-2.3.3-linux-amd64.tar.gz`
### config Containerd

1. 下载安装systemd service 文件
```sh
$ wget https://raw.githubusercontent.com/containerd/containerd/master/containerd.service
$ sudo mv containerd.service /etc/systemd/system/
$ sudo systemctl daemon-reload
```
2. `runtime`和 `VMM`, 这里我们增加 `QEMU` 和 `CLoud Hypervisor`的配置
```sh
$ cat <<-EOF | sudo tee -a "/usr/local/bin/containerd-shim-kata-v2"
#!/bin/bash
# QEMU (Default VMM)
KATA_CONF_FILE=/opt/kata/share/defaults/kata-containers/configuration.toml /opt/kata/bin/containerd-shim-kata-v2 \$@
EOF
$ sudo chmod +x /usr/local/bin/containerd-shim-kata-v2
$ mkdir /etc/kata-containers/
$ sudo cat << 'EOF' > /usr/local/bin/containerd-shim-kata-clh-v2
#!/bin/bash
# Cloud Hypervisor
KATA_CONF_FILE=/etc/kata-containers/configuration.toml /opt/kata/bin/containerd-shim-kata-v2 $@
EOF
$ sudo chmod +x /usr/local/bin/containerd-shim-kata-clh-v2
```

> [!warning] `containerd-shim-kata-v2` 使用的`KATA_CONF_FILE`要放在`/etc/kata-containers`路径，否则可能会报:
> ```
> [root@localhost ~]# sudo nerdctl run --net=none --runtime "io.containerd.kata-clh.v2" --rm -t --name test-kata2 "$image" date
FATA[0000] failed to create shim task: invalid KATA_CONF_FILE "/usr/share/defaults/kata-containers/configuration-clh.toml": only shipped Kata configuration files are accepted
> ```
> 该错误
3. 创建默认的配置文件
```sh
$ sudo mkdir -p /etc/containerd
$ sudo containerd config default >> /etc/containerd/config.toml
```
4. 修改配置文件中的`[plugins."io.containerd.cri.v1.runtime".containerd.rumtimers]` section. 该配置将配置Containerd使用Kata Runtime
```toml
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata-clh]
  runtime_type = "io.containerd.kata-clh.v2"
```

> [!warning] 该步骤中，如果使用新版containerd(`v2.3.3`), 请注意配置的标签，其和 PVM 文档中提到的标签不同。
5. 启动containerd
```sh
sudo systemctl start containerd
sudo systemctl enable containerd
```
5. 验证kata runtime配置是否生效
```sh
[root@localhost ~]# containerd config dump |grep kata
        [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.kata]
          runtime_type = 'io.containerd.kata.v2'
        [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.kata-clh]
          runtime_type = 'io.containerd.kata-clh.v2'
```

# 使用KVM进行验证

## 下载安装 nerdctl
```sh
wget https://github.com/containerd/nerdctl/releases/download/v2.3.5/nerdctl-2.3.5-linux-amd64.tar.gz
tar Cxf /usr/local/bin nerdctl-2.3.5-linux-amd64.tar.gz
```

## 加载内核模块
* kvm-intel
* vhost-vsock
* vmw_vmci
## 简单测试

```sh
# 使用下面这个快一些
image="docker.1ms.run/library/busybox:latest"
sudo nerdctl image pull "$image"
sudo nerdctl run --net=none --runtime "io.containerd.kata.v2" --rm -t --name test-kata "$image" date
sudo nerdctl run --net=none --runtime "io.containerd.kata-clh.v2" --rm -t --name test-kata "$image" date
```

> [!success] 如果最后两个命令都能返回`date`的正确输出，说明执行成功

# PVM 测试

## 编译 Guest/Host内核

1. 使用链接<sup>3</sup>作为Guest/Host 内核源码(也可以使用 链接<sup>6</sup>)
2. 使用链接<sup>4</sup>作为Guest(L2) 内核编译配置
3. 使用链接<sup>5</sup>作为Host (L1)内核编译配置

> [!note] 由于下载的L1 镜像是efi 镜像，需要在编译 L1 host kernel 时，打开`CONFIG_EFI_STUB`

> [!warning] 在L1打开`CONFIG_EFI_STUB`, 和 L2 使用 链接<sup>4</sup>作为编译选项时，需要执行 `make menuconfig`解决 依赖/冲突的编译选项

4. 编译完guest内核后，将guest 内核copy到 L1 的`/opt/kata/share/kata-containers/vmlinux.pvm`。
5. 配置 L1 kernel cmdline 增加 `pti=off`
6. 重启机器，并且重启后执行, `rmmod kvm-intel;modprobe kvm-pvm`
## 配置QEMU 验证PVM

修改`/opt/kata/share/defaults/kata-containers/configuration.toml`, 使用pvm guest内核 + qboot firmware

```
kernel = "/opt/kata/share/kata-containers/vmlinux.pvm"  
firmware = "/opt/kata/share/kata-qemu/qemu/qboot.rom"
```

> [!todo] 
> ![[02-a-pvm-get-started-with-kata#^691d34]]
> 我们这里暂时先不验证这个问题
## 配置 Cloud Hypervisor

## 更新Cloud  Hypervisor

```sh
wget https://github.com/cloud-hypervisor/cloud-hypervisor/releases/download/v53.0/cloud-hypervisor-static -O /opt/kata/bin/cloud-hypervisor
```

原因是:
![[02-a-pvm-get-started-with-kata#^d17536]]

## 具体测试结果

执行
```
image="docker.1ms.run/library/busybox:latest"
sudo nerdctl image pull "$image"
sudo nerdctl run --net=none --runtime "io.containerd.kata.v2" --rm -t --name test-kata "$image" date
sudo nerdctl run --net=none --runtime "io.containerd.kata-clh.v2" --rm -t --name test-kata "$image" date
```

其中 qemu 测试成功, `cloud-hypervisor` 命令执行报下面错误:
[[cloud-hypervisor 启动PVM虚拟机报错]]

而链接<sup>1</sup>中暴露了 `CH`的另一个问题。
![[02-a-pvm-get-started-with-kata#^7953de]] 
![[02-a-pvm-get-started-with-kata#^8ddd3a]]

> [!fail] 根据, [issue](https://github.com/virt-pvm/linux/issues/1) 的堆栈，发现堆栈不一样。所以这应该是另一个问题

> [!tip] 下载<sup>2</sup>时，可以用`gh-proxy.com`加速下载:
> ```
> wget https://gh-proxy.com/https://github.com/virt-pvm/misc/releases/download/test/pvm-kata-vm-img.tar.gz
> ```

**_其他镜像测试_**
1. 使用链接<sup>2</sup> 测试pvm CH场景并未复现问题(其CH的版本是v45)
2. 使用官方45版本的CH以及链接<sup>2</sup>中的CH在ubuntu2403sp3中测试 还是会复现问题
# 参考链接
1. [PVM get stated wit.  kata](https://github.com/virt-pvm/misc/blob/main/pvm-get-started-with-kata.md)
2. [PVM官方提供的VM Image 示例](https://github.com/virt-pvm/misc/releases/download/test/pvm-kata-vm-img.tar.gz)
3. [Github PVM](https://github.com/virt-pvm/linux)
4. [Github PVM guest 6.12.33 kconfig](https://github.com/virt-pvm/misc/blob/main/pvm-guest-6.12.33.config)
5. [Github PVM host 6.12.33 kconfig](https://github.com/virt-pvm/misc/blob/main/pvm-host-6.12.33.config)
6. [My Gitcode PVM](https://gitcode.com/cai-fuqiang/linux-stable/tree/pvm-612)
