---
status: done
show in nav: true
create date: 2026-07-01 10:31:11
complete date: 2026-07-01 11:20:07
tags:
priority: 99
summary:
---
# 配置/安装命令
1. 配置 cargo config
  ```
  [source.crates-io]
  replace-with = 'rsproxy-sparse'
  [source.rsproxy]
  registry = "https://rsproxy.cn/crates.io-index"
  [source.rsproxy-sparse]
  registry = "sparse+https://rsproxy.cn/index/"
  [registries.rsproxy]
  index = "https://rsproxy.cn/crates.io-index"
  [net]
  git-fetch-with-cli = true
  ```
  
2. 配置环境变量
  ```
  # 编辑 ~/.bashrc 追加
  export RUSTUP_DIST_SERVER="https://rsproxy.cn"
  export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
  ```
3. 下载rustup
```
source ~/.bashrc
curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh
```

# 参考链接

1. [rsproxy.cn - A high speed crates.io mirror](https://rsproxy.cn/#getStarted)
2. [ Rust使用国内Crates 源、 rustup源](https://blog.csdn.net/inthat/article/details/106742193)