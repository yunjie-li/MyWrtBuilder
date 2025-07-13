#!/bin/bash

echo "Start Clash Core Download !"
echo "Current Path: $PWD"

mkdir -p files/etc/openclash/core
cd files/etc/openclash/core || (echo "Clash core path does not exist! " && exit)

# Clash Meta
wget https://github.com/vernesong/OpenClash/raw/refs/heads/core/dev/meta/clash-linux-amd64.tar.gz
tar -zxvf clash-linux-amd64.tar.gz
rm -rf clash-linux-amd64.tar.gz
mv clash clash_meta

wget https://github.com/vernesong/OpenClash/raw/refs/heads/core/dev/smart/clash-linux-amd64.tar.gz
tar -zxvf clash-linux-amd64.tar.gz
rm -rf clash-linux-amd64.tar.gz
mv clash clash_smart

# Use clash_dev as default core
mv clash_smart clash

cd files/etc/openclash
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
