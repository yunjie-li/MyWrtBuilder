#!/bin/sh
# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE

# LAN 网络设置
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.2.253'
uci set network.lan.netmask='255.255.255.0'

# WAN 网络设置
uci set network.wan.proto='dhcp'
uci set network.wan=interface
uci set network.wan.device='eth3'

uci set network.wan6=interface
uci set network.wan6.device='eth3'

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface

# 设置 SSH
uci set dropbear.@dropbear[0].Interface=''

uci commit

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="compiled by wwmm"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
