#!/usr/bin/env bash
set -Eeuo pipefail

readonly STATE_DIR="/run/nginx-https-bandwidth-limit"

usage() {
    cat <<'EOF'
用法：
  sudo ./restore-nginx-443-bandwidth.sh <网卡>

示例：
  sudo ./restore-nginx-443-bandwidth.sh bond0
EOF
}

die() {
    echo "错误：$*" >&2
    exit 1
}

[[ ${EUID} -eq 0 ]] || die "请使用 root 权限运行。"
[[ $# -eq 1 ]] || {
    usage
    exit 2
}

DEVICE=$1
[[ ${DEVICE} =~ ^[[:alnum:]_.:-]+$ ]] || die "网卡名称不合法：${DEVICE}"
[[ -d /sys/class/net/${DEVICE} ]] || die "网卡不存在：${DEVICE}"
command -v tc >/dev/null 2>&1 || die "未找到 tc，请安装 iproute/iproute2。"

STATE_FILE="${STATE_DIR}/${DEVICE}.state"
ORIGINAL_FILE="${STATE_DIR}/${DEVICE}.original-qdisc.txt"

[[ -f ${STATE_FILE} ]] || die "未找到 ${DEVICE} 的限速状态文件：${STATE_FILE}"

RECORDED_DEVICE=$(awk -F= '$1 == "DEVICE" { print $2; exit }' "${STATE_FILE}")
[[ ${RECORDED_DEVICE} == "${DEVICE}" ]] || die "状态文件中的网卡与参数不一致。"

CURRENT_ROOT_QDISC=$(tc qdisc show dev "${DEVICE}" | awk '/ root / { print; exit }')
if ! grep -Eq '^qdisc htb 80: root([[:space:]]|$)' <<<"${CURRENT_ROOT_QDISC}"; then
    die "当前根队列不是本脚本创建的 htb 80:，拒绝删除：${CURRENT_ROOT_QDISC}"
fi

tc qdisc del dev "${DEVICE}" root

echo "已删除 ${DEVICE} 上的PXE/NFS/HTTP带宽保障规则。"
if [[ -f ${ORIGINAL_FILE} ]]; then
    echo "变更前的根队列记录：$(<"${ORIGINAL_FILE}")"
fi
echo "当前根队列：$(tc qdisc show dev "${DEVICE}" | awk '/ root / { print; exit }')"

rm -f "${STATE_FILE}" "${ORIGINAL_FILE}"
rmdir "${STATE_DIR}" >/dev/null 2>&1 || true
