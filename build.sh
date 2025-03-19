#!/bin/bash

# 打印 info
make info

# 主配置名称
PROFILE="generic"

PACKAGES=""

# Argon 主题
PACKAGES="$PACKAGES luci-theme-argon luci-i18n-argon-config-zh-cn"

# 常用系统管理组件

# Diskman 磁盘管理
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"

# 常用软件服务

# OpenClash 代理
PACKAGES="$PACKAGES luci-app-openclash"

# 常用的网络存储组件

# 文件助手
PACKAGES="$PACKAGES luci-app-fileassistant"
# TTYD
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
# UPNP
PACKAGES="$PACKAGES luci-i18n-upnp-zh-cn"


# 界面翻译补全
PACKAGES="$PACKAGES luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-i18n-opkg-zh-cn"

# Packages 文件夹下的 ipk 包
PACKAGES="$PACKAGES luci-i18n-nikki-zh-cn"
PACKAGES="$PACKAGES luci-i18n-lucky-zh-cn"
# PACKAGES="$PACKAGES luci-i18n-mosdns-zh-cn"

# 一些其他可能有用的包

# zsh 终端
PACKAGES="$PACKAGES zsh"
PACKAGES="$PACKAGES git"
PACKAGES="$PACKAGES wget-ssl"
# Vim 完整版，带语法高亮
PACKAGES="$PACKAGES vim-fuller"
# Netdata 系统监控界面
PACKAGES="$PACKAGES netdata"

# 一些自定义文件
FILES="files"

# 禁用 openssh-server 的 sshd 服务和 docker 的 dockerd 服务以防止冲突
DISABLED_SERVICES="sshd dockerd"

make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="$FILES" DISABLED_SERVICES="$DISABLED_SERVICES"
