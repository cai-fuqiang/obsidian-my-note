---
share_link: https://share.note.sx/tzzzf03h#6gUF34W9fkTotJUoH4esqw
share_updated: 2026-08-20T14:07:29+08:00
---
```sh
> /tmp/kata-dragonball-perf.log
t0=$(date +%s%3N)
POD=$(crictl runp --runtime kata-nydus test/pod-nydus-kata.json)
t1=$(date +%s%3N)
CTR=$(crictl create $POD test/container-busybox-sleep.json test/pod-nydus-kata.json)
t2=$(date +%s%3N)
crictl start $CTR > /dev/null
t3=$(date +%s%3N)
echo "runp=$((t1-t0))ms create=$((t2-t1))ms start=$((t3-t2))ms total=$((t3-t0))ms"


# 验证 exec
crictl exec $CTR echo hello
#
# # 查看 shim 内部拆解
grep -E "sandbox_start_total|restore_vmm|connect_agent_server|create_sandbox_rpc" \
    /tmp/kata-dragonball-perf.log
#
# 清理

crictl stop $CTR
crictl rm $CTR
crictl rmp -f $POD
```