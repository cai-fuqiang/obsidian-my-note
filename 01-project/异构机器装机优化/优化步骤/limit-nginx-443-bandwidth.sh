#!/usr/bin/env bash
set -Eeuo pipefail

readonly TFTP_PERCENT=20
readonly NFS_PERCENT=20
readonly NGINX_PERCENT=50
readonly NGINX_PORT=80
readonly RPCBIND_PORT=111
readonly MOUNTD_PORT=20048
readonly NFS_PORT=2049
readonly QDISC_HANDLE="80:"
readonly STATE_DIR="/run/nginx-https-bandwidth-limit"

usage() {
    cat <<'EOF'
用法：
  sudo ./limit-nginx-443-bandwidth.sh <网卡> <总带宽-Mbit/s> <PXE客户端网段> [PXE客户端网段...]

示例：
  sudo ./limit-nginx-443-bandwidth.sh eth0 25000 11.214.98.0/24 11.214.99.0/24

TFTP传输使用动态UDP源端口，因此按发往PXE客户端网段的UDP流量进行分类。
最多支持8个PXE客户端网段。
EOF
}

die() {
    echo "错误：$*" >&2
    exit 1
}

valid_ipv4_cidr() {
    local cidr=$1
    local address prefix octet
    local -a octets

    [[ ${cidr} == */* ]] || return 1
    address=${cidr%/*}
    prefix=${cidr#*/}
    [[ ${prefix} =~ ^[0-9]+$ ]] || return 1
    (( prefix >= 0 && prefix <= 32 )) || return 1

    IFS=. read -r -a octets <<<"${address}"
    (( ${#octets[@]} == 4 )) || return 1
    for octet in "${octets[@]}"; do
        [[ ${octet} =~ ^[0-9]+$ ]] || return 1
        (( 10#${octet} <= 255 )) || return 1
    done
}

[[ ${EUID} -eq 0 ]] || die "请使用 root 权限运行。"
[[ $# -ge 3 && $# -le 10 ]] || {
    usage
    exit 2
}

DEVICE=$1
TOTAL_MBIT=$2
shift 2
PXE_CIDRS=("$@")

[[ ${DEVICE} =~ ^[[:alnum:]_.:-]+$ ]] || die "网卡名称不合法：${DEVICE}"
[[ -d /sys/class/net/${DEVICE} ]] || die "网卡不存在：${DEVICE}"
command -v tc >/dev/null 2>&1 || die "未找到 tc，请安装 iproute/iproute2。"

[[ ${TOTAL_MBIT} =~ ^[0-9]+$ ]] || die "总带宽必须是整数，单位为 Mbit/s。"
(( TOTAL_MBIT >= 10 )) || die "检测到的总带宽异常：${TOTAL_MBIT} Mbit/s"
for cidr in "${PXE_CIDRS[@]}"; do
    valid_ipv4_cidr "${cidr}" || die "PXE客户端网段不合法：${cidr}"
done

TFTP_MBIT=$((TOTAL_MBIT * TFTP_PERCENT / 100))
NFS_MBIT=$((TOTAL_MBIT * NFS_PERCENT / 100))
NGINX_MBIT=$((TOTAL_MBIT * NGINX_PERCENT / 100))
OTHER_MBIT=$((TOTAL_MBIT - TFTP_MBIT - NFS_MBIT - NGINX_MBIT))
PXE_CIDR_LIST=$(IFS=,; printf '%s' "${PXE_CIDRS[*]}")
STATE_FILE="${STATE_DIR}/${DEVICE}.state"
ORIGINAL_FILE="${STATE_DIR}/${DEVICE}.original-qdisc.txt"

[[ ! -e ${STATE_FILE} ]] || die "${DEVICE} 已存在限速状态，请先运行恢复脚本。"

ORIGINAL_ROOT_QDISC=$(tc qdisc show dev "${DEVICE}" | awk '/ root / { print; exit }')
[[ -n ${ORIGINAL_ROOT_QDISC} ]] || die "无法读取 ${DEVICE} 的根队列。"

# handle 0: 通常表示内核默认队列；发现自定义根队列时拒绝覆盖。
if ! grep -Eq '^qdisc [^ ]+ 0: root([[:space:]]|$)' <<<"${ORIGINAL_ROOT_QDISC}"; then
    die "${DEVICE} 已有自定义根队列，拒绝覆盖：${ORIGINAL_ROOT_QDISC}"
fi

install -d -m 0700 "${STATE_DIR}"
printf '%s\n' "${ORIGINAL_ROOT_QDISC}" >"${ORIGINAL_FILE}"
{
    printf 'DEVICE=%s\n' "${DEVICE}"
    printf 'TOTAL_MBIT=%s\n' "${TOTAL_MBIT}"
    printf 'TFTP_MBIT=%s\n' "${TFTP_MBIT}"
    printf 'NFS_MBIT=%s\n' "${NFS_MBIT}"
    printf 'NGINX_MBIT=%s\n' "${NGINX_MBIT}"
    printf 'OTHER_MBIT=%s\n' "${OTHER_MBIT}"
    printf 'PXE_CIDRS=%s\n' "${PXE_CIDR_LIST}"
    printf 'NGINX_PORT=%s\n' "${NGINX_PORT}"
    printf 'RPCBIND_PORT=%s\n' "${RPCBIND_PORT}"
    printf 'MOUNTD_PORT=%s\n' "${MOUNTD_PORT}"
    printf 'NFS_PORT=%s\n' "${NFS_PORT}"
} >"${STATE_FILE}"
chmod 0600 "${STATE_FILE}" "${ORIGINAL_FILE}"

ROOT_REPLACED=0
rollback_on_error() {
    local rc=$?
    trap - ERR INT TERM
    if (( ROOT_REPLACED == 1 )); then
        tc qdisc del dev "${DEVICE}" root >/dev/null 2>&1 || true
    fi
    rm -f "${STATE_FILE}" "${ORIGINAL_FILE}"
    echo "配置失败，已尝试恢复 ${DEVICE} 的默认队列。" >&2
    exit "${rc}"
}
trap rollback_on_error ERR INT TERM

tc qdisc replace dev "${DEVICE}" root handle "${QDISC_HANDLE}" htb default 20 r2q 10000
ROOT_REPLACED=1

tc class add dev "${DEVICE}" parent "${QDISC_HANDLE}" classid 80:1 \
    htb rate "${TOTAL_MBIT}mbit" ceil "${TOTAL_MBIT}mbit"

# 各类的 ceil 均为总带宽；服务空闲时，其他类可以借用其全部空闲带宽。
tc class add dev "${DEVICE}" parent 80:1 classid 80:10 \
    htb rate "${NGINX_MBIT}mbit" ceil "${TOTAL_MBIT}mbit" prio 2

tc class add dev "${DEVICE}" parent 80:1 classid 80:20 \
    htb rate "${OTHER_MBIT}mbit" ceil "${TOTAL_MBIT}mbit" prio 3

# TFTP/PXE 使用最高优先级，并获得独立保证带宽。
tc class add dev "${DEVICE}" parent 80:1 classid 80:30 \
    htb rate "${TFTP_MBIT}mbit" ceil "${TOTAL_MBIT}mbit" prio 0

# NFS/RPC 使用次高优先级和独立保证带宽。
tc class add dev "${DEVICE}" parent 80:1 classid 80:40 \
    htb rate "${NFS_MBIT}mbit" ceil "${TOTAL_MBIT}mbit" prio 1

tc qdisc add dev "${DEVICE}" parent 80:10 handle 810: fq_codel
tc qdisc add dev "${DEVICE}" parent 80:20 handle 820: fq_codel
tc qdisc add dev "${DEVICE}" parent 80:30 handle 830: fq_codel
tc qdisc add dev "${DEVICE}" parent 80:40 handle 840: fq_codel

# TFTP服务端使用动态UDP源端口，按PXE客户端网段匹配出站UDP流量。
TFTP_PREF=1
for cidr in "${PXE_CIDRS[@]}"; do
    tc filter add dev "${DEVICE}" protocol ip parent "${QDISC_HANDLE}" prio "${TFTP_PREF}" u32 \
        match ip protocol 17 0xff \
        match ip dst "${cidr}" \
        flowid 80:30
    TFTP_PREF=$((TFTP_PREF + 1))
done

# 服务器出站 Nginx 数据包的源端口为 80。当前规则匹配 IPv4。
tc filter add dev "${DEVICE}" protocol ip parent "${QDISC_HANDLE}" prio 10 u32 \
    match ip protocol 6 0xff \
    match ip sport "${NGINX_PORT}" 0xffff \
    flowid 80:10

# 显式匹配NFS TCP/2049，并进入NFS/RPC保证带宽类。
tc filter add dev "${DEVICE}" protocol ip parent "${QDISC_HANDLE}" prio 20 u32 \
    match ip protocol 6 0xff \
    match ip sport "${NFS_PORT}" 0xffff \
    flowid 80:40

# NFSv3 挂载前通过 rpcbind TCP/111 查询 mountd 端口。
tc filter add dev "${DEVICE}" protocol ip parent "${QDISC_HANDLE}" prio 21 u32 \
    match ip protocol 6 0xff \
    match ip sport "${RPCBIND_PORT}" 0xffff \
    flowid 80:40

# mountd TCP/20048 返回 export 对应的根文件句柄。
tc filter add dev "${DEVICE}" protocol ip parent "${QDISC_HANDLE}" prio 22 u32 \
    match ip protocol 6 0xff \
    match ip sport "${MOUNTD_PORT}" 0xffff \
    flowid 80:40

trap - ERR INT TERM

echo "已生效："
echo "  网卡总带宽：${TOTAL_MBIT} Mbit/s"
echo "  TFTP/PXE保证带宽：${TFTP_MBIT} Mbit/s，优先级0，最高${TOTAL_MBIT} Mbit/s"
echo "  NFS/RPC保证带宽：${NFS_MBIT} Mbit/s，优先级1，最高${TOTAL_MBIT} Mbit/s"
echo "  Nginx TCP/${NGINX_PORT}保证带宽：${NGINX_MBIT} Mbit/s，优先级2，最高${TOTAL_MBIT} Mbit/s"
echo "  其他流量保证带宽：${OTHER_MBIT} Mbit/s，优先级3，最高${TOTAL_MBIT} Mbit/s"
echo "  PXE客户端网段：${PXE_CIDR_LIST}"
echo
echo "查看统计：tc -s class show dev ${DEVICE}"
echo "查看 TFTP/PXE 命中："
for ((pref = 1; pref < TFTP_PREF; pref++)); do
    echo "  tc -s -d filter show dev ${DEVICE} parent 80: pref ${pref}"
done
echo "查看 NFS 命中："
echo "  tc -s -d filter show dev ${DEVICE} parent 80: pref 20"
echo "  tc -s -d filter show dev ${DEVICE} parent 80: pref 21"
echo "  tc -s -d filter show dev ${DEVICE} parent 80: pref 22"
echo "恢复配置：sudo ./restore-nginx-443-bandwidth.sh ${DEVICE}"
