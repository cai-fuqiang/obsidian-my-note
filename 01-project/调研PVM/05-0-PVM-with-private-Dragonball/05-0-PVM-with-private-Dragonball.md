---
share_link: https://share.note.sx/ajw9ss0w#cwMfglbG1z5Ful4Jk2/ycA
share_updated: 2026-08-20T14:08:13+08:00
---
# 部署流程

## PVM内核部署
+ guest L1 内核
	* 下载内核 [链接](https://github.com/cai-fuqiang/linux-stable/tree/pvm-612)
	* 编译选项: [链接](https://github.com/virt-pvm/misc/blob/main/pvm-host-6.12.33.config)
+ guest L2 内核
	+ 下载内核: (和host一样)
	+ 编译选项: [链接](https://github.com/virt-pvm/misc/blob/main/pvm-guest-6.12.33.config)
编译并安装

配置 guest L1 cmdline：
1. 修改`/etc/default/grub`增加 `nokpti`
2. `grub2-mkconfig -o /boot/efi/EFI/openeuler/grub.cfg`

重启机器
## 编译安装kata

1. 在下面链接下载kata源码, [定制kata git 链接](http://xingyun.jd.com/codingRoot/wangfuqiang49/kata-containers/tree/feature%2Fsnapshot-restore)
2. 编译:
```
pushd kata-containers/src/runtime-rs
make && sudo -E "PATH=$PATH" make install
```
3. 配置 `dragonball`为默认的配置文件(待测试需不需要)
```
mkdir -p /etc/kata-containers/
sudo install -o root -g root -m 0640 \
 /usr/share/defaults/kata-containers/runtime-rs/configuration-dragonball.toml \
 /etc/kata-containers
```

## 安装nerdctl
```
wget https://github.com/containerd/nerdctl/releases/download/v2.3.5/nerdctl-2.3.5-linux-amd64.tar.gz
tar Cxf /usr/local/bin nerdctl-2.3.5-linux-amd64.tar.gz
```
## 安装containerd
1. 从github下载containerd, 链接 [github release: containerd v2.3.4](https://github.com/containerd/containerd/releases/download/v2.3.4/containerd-2.3.4-linux-amd64.tar.gz)
2. 解压:
```
tar -C /usr/local -xvf containerd-2.3.4-linux-amd64.tar.gz
```
3. 下载 [containerd systemd service file](https://raw.githubusercontent.com/containerd/containerd/master/containerd.service), 并安装在 `/etc/systemd/system/containerd.service`路径
4. 生成默认`containerd`配置文件
```
mkdir /etc/containerd
containerd config default >> /etc/containerd/config.toml
```
5. 编辑`/etc/containerd/config.toml`增加:
```
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"     
```
6. 编辑`/usr/share/defaults/kata-containers/runtime-rs/configuration.toml`修改
```
# root vmlinux为PVM定制
kernel = "/root/vmlinux"
image = "/usr/share/kata-containers/kata-containers.img"
```

# 使用nerdctl简单测试
1. 加载pvm模块
```
modprobe -r kvm_intel
modprobe kvm_pvm
```
2. 使用下面命令启动
```
[root@localhost ~]# image="docker.1ms.run/library/busybox:latest"
[root@localhost ~]# nerdctl run --net=none --runtime "io.containerd.kata.v2" --rm -t --name test-kata "$image" date
Wed Aug 19 03:47:36 UTC 2026
```
# 测试快照功能

## 安装其他依赖包
* cri-tools(yum安装)
## 配置containerd
1. 配置`/etc/containerd/config.toml`, 增加`kata-nydus`, 和 `kata-overlayfs`
```toml
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.kata-nydus]
  runtime_type = "io.containerd.kata.v2"
  snapshotter = 'nydus'
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.kata-overlayfs]
  runtime_type = "io.containerd.kata.v2"
  snapshotter = 'overlayfs'
```
2. BoltDB优化(消除 fsync 串行瓶颈, 提升并发性能)
```
[plugins.'io.containerd.metadata.v1.bolt']
  no_sync = true
```
3. 重启containerd
```
systemctl restart containerd
```

## 配置 nydus

参考 [[05-a-containerd-with-nydus| config nydus]]

## 准备镜像

* 准备 pause 镜像
```
ctr -n k8s.io images pull --snapshotter nydus registry.aliyuncs.com/google_containers/pause:3.10.2
```
<!--nerdctl pull registry.aliyuncs.com/google_containers/pause:3.10.2-->
* busybox 镜像准备
```
ctr -n k8s.io images pull --snapshotter nydus docker.1ms.run/library/busybox:latest
```
* 修改`/etc/containerd/config.toml`
```
[plugins.'io.containerd.cri.v1.images'.pinned_images]
   sandbox = "registry.aliyuncs.com/google_containers/pause:3.10.2"
```

## 测试冷启动

额外准备工作
```
rm -f  /etc/systemd/system/containerd.service.d/override.conf
```

1. 创建sandbox ([[pod-nydus-kata.json]])
```
crictl runp --runtime kata-nydus test/pod-nydus-kata.json
51ea7a60732d6467789e80b28154dcbb6fd41a77638beeb315a71946139cd793
```
验证是否创建成功:
```
[root@localhost ~]# crictl pods
POD ID              CREATED              STATE               NAME                     NAMESPACE           ATTEMPT             RUNTIME
51ea7a60732d6       About a minute ago   Ready               crictl-kata-nydus-test   default             1                   kata-nydus
```
2. 使用sandbox + busybox image 创建容器 ([[container-busybox-sleep.json]])
```
crictl create 51ea7a60732d6 test/container-busybox-sleep.json test/pod-nydus-kata.json
6fd46cf727572a2b76f1bbb040da6d8966e5524279b689b3aa28b9fbade0e5b0
```
查看容器是否创建成功:
```
[root@localhost ~]# crictl ps -a
CONTAINER           IMAGE                            CREATED             STATE               NAME                ATTEMPT             POD ID              POD
6fd46cf727572       docker.1ms.run/library/busybox   32 seconds ago      Created             busybox             0                   51ea7a60732d6       unknown

```
3. 启动容器
```
crictl start 6fd46cf727572
```

查看是否启动成功:
```
[root@localhost ~]# crictl ps
CONTAINER           IMAGE                            CREATED              STATE               NAME                ATTEMPT             POD ID              POD
6fd46cf727572       docker.1ms.run/library/busybox   About a minute ago   Running             busybox             0                   51ea7a60732d6       unknown
```
4. 销毁资源
	+ 关闭容器: `crictl stop 6fd46cf727572`
	+ 删除容器: `crictl rm 6fd46cf727572`
	* 删除pod:  `crictl rmp -f 51ea7a60732d6`

可以通过 [[start_a_pod_and_state.sh]] 来测试:

> [!warning] 
> 1. 使用kvm
> ```
> runp=2575ms create=36ms start=91ms total=2702ms
> ```
> 2. 使用pvm
> ```
> runp=1761ms create=37ms start=87ms total=1885ms
> ```
> 从这里看pvm确实要优秀一些


## save

[[save_a_snap.sh]]

## restore

[[restore_a_pod.sh]]

restore 成功打印如下:
```
runp=297ms create=48ms start=93ms total=438ms
hello
[PERF-DB] ts_ms=1787205619983 sid=d6d6eae3076a76e93376f033e824c48d4ebe6b5f65728237b1f559d7b2783120 dragonball_restore_vmm_action_ms=27 memory_path=/mnt/firecracker/dragonball-snapshots/release-20260622-v2/memory.bin
[PERF-DB] ts_ms=1787205619990 connect_agent_server_ms=6 address=hvsock:///run/kata/d6d6eae3076a76e93376f033e824c48d4ebe6b5f65728237b1f559d7b2783120/root/kata.hvsock port=1024
d5360b17e628225d9d69ec5b81b0f14484179f7aef1f24f3ba1755b6524c7913
d5360b17e628225d9d69ec5b81b0f14484179f7aef1f24f3ba1755b6524c7913
Stopped sandbox d6d6eae3076a76e93376f033e824c48d4ebe6b5f65728237b1f559d7b2783120
Removed sandbox d6d6eae3076a76e93376f033e824c48d4ebe6b5f65728237b1f559d7b2783120
```

> [!bug] 在restore 时，kata 可能因为vsock链接不上，导致restore失败，这时候,containerd 打印
> ```
> Aug 20 05:11:13 localhost.localdomain kata[12238]: [    9.273202] vmw_vsock_virtio_transport virtio1: rx:id 0 is not a head!
> 
Aug 20 05:11:20 localhost.localdomain containerd[12044]: time="2026-08-20T05:11:20.432291610Z" level=error msg="failed to delete task" error="rpc error: code = Unknown desc = Others(\"failed to handle message >
> ```
> 原因待定位，不是稳定复现

# 附录
## 部署kata编译环境
### rust
```
rustup target add x86_64-unknown-linux-musl
yum install -y musl-gcc cmake
```

## 镜像源

本次测试使用`docker.1ms.run`, 如果在未联网的机器中使用修改`/etc/hosts`添加域名联网还需要增加 
```
cloudfront-docker-cf.mrs.1ms.run
```

该域名可以通过`tcpdump -i any -n port 53 -v` 命令抓取得到

## 配置containerd遇到的错误
如果做完步骤 [[05-0-PVM-with-private-Dragonball#安装containerd|安装containerd]] 步骤5，直接使用`nerdctl` 启动容器则会遇到:
```
[root@localhost ~]# nerdctl run --net=none --runtime "io.containerd.kata.v2" --rm -t --name test-kata "$image" date
FATA[0000] failed to create shim task: Others("failed to handle message try init runtime instance\n\nCaused by:\n    0: load config\n    1: load TOML config failed (tried [\"/etc/kata-containers/runtime-rs/configuration.toml\", \"/usr/share/defaults/kata-containers/runtime-rs/configuration.toml\", \"/opt/kata/share/defaults/kata-containers/runtime-rs/configuration.toml\"])\n    2: guest kernel image file /usr/share/kata-containers/vmlinux-dragonball-experimental.container is invalid: No such file or directory (os error 2)")
```

> [!missing] 原因是源码安装的kata 没有 `vmlinux` 和 `rootfs`镜像, 需要从 [kata release](https://github.com/kata-containers/kata-containers/releases/tag/4.0.0) 的压缩包中获取。但是在本测试中，vmlinux 是PVM定制内核不用替换

# 参考链接
1. [github kata release](https://github.com/kata-containers/kata-containers/releases/)
