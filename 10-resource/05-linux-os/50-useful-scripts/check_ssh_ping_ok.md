---
share_link: https://share.note.sx/fikqutha#KrEoZYc+p98pKKyveJEoBg
share_updated: 2026-08-03T15:38:00+08:00
---
```
#!/bin/bash
set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # 无色

get_ssh_ping_ok()
{
	ip=$1
    	if ping -c 1 -W 1 "$ip" &>/dev/null; then
		ping_result="${GREEN}yes${NC}"
    	else
		ping_result="${RED}no${NC}"
	fi

	# 检查SSH端口
    	if nc -z -w2 "$ip" 22 &>/dev/null; then
		ssh_result="${GREEN}yes${NC}"
    	else
		ssh_result="${RED}no${NC}"
    	fi

    	printf "%-16s %-10b %-10b\n" "$ip" "$ping_result" "$ssh_result"
}

printf "%-16s %-10b %-10b\n" IP PING SSH

for HOST_M_IP in `cat host_all.txt`
do
	get_ssh_ping_ok $HOST_M_IP 
done
```