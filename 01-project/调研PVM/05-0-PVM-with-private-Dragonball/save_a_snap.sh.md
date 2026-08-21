---
share_link: https://share.note.sx/vl1sgo64#z35a7e+wWg22+9Nsh4DpJA
share_updated: 2026-08-20T14:07:26+08:00
---
```sh
# 切为 save 模式

cat > /etc/systemd/system/containerd.service.d/override.conf << 'EOF'
[Service]
Environment=KATA_DB_SAVE_SNAPSHOT=true
Environment=KATA_DB_SAVE_SNAPSHOT_AFTER_AGENT_READY=true
Environment=KATA_DB_SNAPSHOT_BASE_DIR=/mnt/firecracker/dragonball-snapshots
Environment=KATA_DB_TEMPLATE_ID=local-snapshot-new
Environment=KATA_DB_LOAD_SNAPSHOT=
Environment=KATA_DB_TEMPLATE_MEMORY_BACKING=
EOF

echo "2000" > /tmp/kata-db-sleep-after-start-vm-ms
systemctl daemon-reload && systemctl restart containerd && sleep 3

SAVE_DIR=/mnt/firecracker/dragonball-snapshots/local-snapshot-new

rm -rf $SAVE_DIR
mkdir -p $SAVE_DIR

# 执行 save
crictl runp --runtime kata-nydus test/pod-nydus-kata.json

sleep 3
# 等待 3 秒确认 snapshot 生成
ls /mnt/firecracker/dragonball-snapshots/local-snapshot-new/
# 清理 save 环境
crictl pods -q | xargs -r -n1 sh -c 'crictl stopp $0; crictl rmp $0'
rm -f /tmp/kata-db-sleep-after-start-vm-ms

# 拷贝到 tmpfs
cp ${SAVE_DIR}/memory.bin /dev/shm/memory-template.bin

RESTORE_DIR=/mnt/firecracker/dragonball-snapshots/release-20260622-v2

rm -rf $RESTORE_DIR
mkdir -p $RESTORE_DIR

cp ${SAVE_DIR}/memory.bin $SAVE_DIR/state.json $SAVE_DIR/vm_state.json $RESTORE_DIR

# 切为 restore 模式
cat > /etc/systemd/system/containerd.service.d/override.conf << 'EOF'
[Service]
Environment=KATA_DB_LOAD_SNAPSHOT=true
Environment=KATA_DB_SNAPSHOT_BASE_DIR=/mnt/firecracker/dragonball-snapshots
Environment=KATA_DB_TEMPLATE_ID=local-snapshot-new
Environment=KATA_DB_SAVE_SNAPSHOT=
Environment=KATA_DB_TEMPLATE_DISABLE_PREALLOC=true
Environment=KATA_DB_TEMPLATE_MEMORY_BACKING=/dev/shm/memory-template.bin
EOF

systemctl daemon-reload && systemctl restart containerd && sleep 3
```