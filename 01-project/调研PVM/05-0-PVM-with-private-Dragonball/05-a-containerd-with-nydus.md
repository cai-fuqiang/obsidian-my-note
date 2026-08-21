# 安装依赖
* cni
	* ` wget https://github.com/containernetworking/plugins/releases/download/v1.9.1/cni-plugins-linux-amd64-v1.9.1.tgz`
	* `mkdir -p /opt/cni/bin/`
	* `tar xf cni-plugins-linux-amd64-v1.9.1.tgz -C /opt/cni/bin/`
# 安装nydus
* 安装`nydus-static`
```sh
wget https://github.com/dragonflyoss/nydus/releases/download/v2.4.5/nydus-static-2.4.5-linux-amd64.rpm
rpm -ivh nydus-static-*.rpm
```
* 安装 `nydus-snapshotter`
```sh
wget https://github.com/containerd/nydus-snapshotter/releases/download/v0.15.15/nydus-snapshotter-v0.15.15-linux-amd64.tar.gz
tar vxf nydus-snapshotter-v0.15.15-linux-amd64.tar.gz -C /usr/
```

# convert to nydus image

为了方便转换和运行 Nydus 镜像, 我们使用`containerd` 作为本地镜像源:
* 配置国内源: `docker.1ms.run`
   + `mkdir -p  /etc/containerd/certs.d/docker.io`
   * 编辑文件 /etc/containerd/certs.d/docker.io/hosts.toml
```toml
server = "https://registry-1.docker.io"
[host."https://docker.1ms.run"]
  capabilities = ["pull", "resolve"]
```

运行 local registry:
```
nerdctl run -d --restart=always -p 5000:5000 --name registry registry:2
```

> [!warning] 如果要使用该命令创建本地 `local registry`, 需要在pvm 内核打开很多iptables 选项

执行下面命令做镜像转换:

```sh
nydusify convert --source docker.1ms.run/library/ubuntu --target localhost:5000/ubuntu-nydus
```

# Start Nydus Snapshotter
* 在 `/etc/nydus/nydusd-config.fusedev.json` 中准备 `nydusd` 配置：
```sh
sudo tee /etc/nydus/nydusd-config.fusedev.json > /dev/null << EOF
{
  "device": {
    "backend": {
      "type": "registry",
      "config": {
        "scheme": "",
        "skip_verify": true,
        "timeout": 5,
        "connect_timeout": 5,
        "retry_limit": 4,
        "auth": ""
      }
    },
    "cache": {
      "type": "blobcache",
      "config": {
        "work_dir": "cache"
      }
    }
  },
  "mode": "direct",
  "digest_validate": false,
  "iostats_files": false,
  "enable_xattr": true,
  "fs_prefetch": {
    "enable": true,
    "threads_count": 4
  }
}
EOF
```
* 请确保 nydus 快照器的默认根目录为空
```
rm -rf /var/lib/containerd/io.containerd.snapshotter.v1.nydus
```
* Start `containerd-nydus-grpc`
```
nohup  /usr/bin/containerd-nydus-grpc \
    --nydusd-config /etc/nydus/nydusd-config.fusedev.json  \
    --log-to-stdout > /tmp/containerd-nydus-grpc.log 2>&1 &
```

# Configure as Containerd Runtime-Level Snapshotter

* 配置 `/etc/containerd/config.toml`
```toml
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.kata-nydus]
  runtime_type = "io.containerd.kata.v2"
  snapshotter = 'nydus'
[proxy_plugins]
  [proxy_plugins.nydus]
    type = "snapshot"
    address = "/run/containerd-nydus/containerd-nydus-grpc.sock"
```

# 参考链接
