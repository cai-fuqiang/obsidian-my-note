---
share_link: https://share.note.sx/xcb3ce9e#MQLwDx1ZeEW6gXnt3ZsnSw
share_updated: 2026-08-20T14:07:23+08:00
---
```sh
mkdir -p /etc/systemd/system/containerd.service.d/
# # 创建 snapshot 目录
# SNAPSHOT_DIR=/mnt/firecracker/dragonball-snapshots/release-20260622-v2
# mkdir -p $SNAPSHOT_DIR
# # 拷贝 snapshot 文件
# cp snapshot/memory.bin snapshot/state.json snapshot/vm_state.json $SNAPSHOT_DIR/
# #
# # 将 memory.bin 放到 tmpfs (关键! 确保 mmap page fault 走内存而非磁盘)
# cp snapshot/memory.bin /dev/shm/memory-template.bin

cat > /etc/systemd/system/containerd.service.d/override.conf << 'EOF'
[Service]
Environment=KATA_DB_LOAD_SNAPSHOT=true
Environment=KATA_DB_SNAPSHOT_BASE_DIR=/mnt/firecracker/dragonball-snapshots
Environment=KATA_DB_TEMPLATE_ID=release-20260622-v2
Environment=KATA_DB_SAVE_SNAPSHOT=
Environment=KATA_DB_TEMPLATE_DISABLE_PREALLOC=true
Environment=KATA_DB_TEMPLATE_MEMORY_BACKING=/dev/shm/memory-template.bin
EOF

systemctl daemon-reload && systemctl restart containerd && sleep 3

sh start_a_pod_and_stat.sh
```