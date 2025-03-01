#!/bin/bash
set -e

# 配置 GitHub API 访问令牌（如果有的话）
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
if [ -n "$GITHUB_TOKEN" ]; then
  AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
else
  AUTH_HEADER=""
fi

# 原始链接文件
URL_FILE="external-package-urls.txt"

# 更新 luci-app-lucky 相关包
update_lucky_packages() {
  echo "Updating lucky packages..."
  
  # 获取最新版本
  LATEST_RELEASE=$(curl -s -H "$AUTH_HEADER" "https://api.github.com/repos/gdy666/luci-app-lucky/releases/latest")
  if [ $? -ne 0 ] || [ -z "$LATEST_RELEASE" ]; then
    echo "Failed to get latest release for luci-app-lucky"
    return 1
  fi
  
  # 提取版本号和下载URL
  VERSION=$(echo "$LATEST_RELEASE" | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
  if [ -z "$VERSION" ]; then
    echo "Failed to extract version from release data"
    return 1
  fi
  
  echo "Found latest version: $VERSION"
  
  # 构建新的下载链接
  BASE_URL="https://github.com/gdy666/luci-app-lucky/releases/download/$VERSION"
  
  # 获取资产列表
  ASSETS=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4)
  
  # 查找匹配的资产
  LUCI_APP_LUCKY=$(echo "$ASSETS" | grep "luci-app-lucky_.*_all.ipk" | head -1)
  LUCI_I18N_LUCKY=$(echo "$ASSETS" | grep "luci-i18n-lucky-zh-cn_.*_all.ipk" | head -1)
  LUCKY_X86_64=$(echo "$ASSETS" | grep "lucky_.*_Openwrt_x86_64.ipk" | head -1)
  
  # 如果找不到资产，使用构建的URL
  if [ -z "$LUCI_APP_LUCKY" ]; then
    LUCI_APP_LUCKY="$BASE_URL/luci-app-lucky_2.2.2-r1_all.ipk"
    echo "Warning: Could not find luci-app-lucky asset, using fallback URL"
  fi
  
  if [ -z "$LUCI_I18N_LUCKY" ]; then
    LUCI_I18N_LUCKY="$BASE_URL/luci-i18n-lucky-zh-cn_25.051.12356.38229cf_all.ipk"
    echo "Warning: Could not find luci-i18n-lucky asset, using fallback URL"
  fi
  
  if [ -z "$LUCKY_X86_64" ]; then
    LUCKY_VERSION=$(echo "$VERSION" | sed 's/^v//')
    LUCKY_X86_64="$BASE_URL/lucky_${LUCKY_VERSION}_Openwrt_x86_64.ipk"
    echo "Warning: Could not find lucky_x86_64 asset, using fallback URL"
  fi
  
  # 更新链接
  sed -i -e "s|https://github.com/gdy666/luci-app-lucky/releases/download/.*luci-app-lucky_.*_all.ipk|$LUCI_APP_LUCKY|" \
         -e "s|https://github.com/gdy666/luci-app-lucky/releases/download/.*luci-i18n-lucky-zh-cn_.*_all.ipk|$LUCI_I18N_LUCKY|" \
         -e "s|https://github.com/gdy666/luci-app-lucky/releases/download/.*lucky_.*_Openwrt_x86_64.ipk|$LUCKY_X86_64|" \
         "$URL_FILE"
  
  echo "Updated lucky packages URLs"
}

# 更新 adguardhome 包
update_adguardhome_package() {
  echo "Updating AdGuardHome package..."
  
  # 获取最新版本
  LATEST_RELEASE=$(curl -s -H "$AUTH_HEADER" "https://api.github.com/repos/rufengsuixing/luci-app-adguardhome/releases/latest")
  if [ $? -ne 0 ] || [ -z "$LATEST_RELEASE" ]; then
    echo "Failed to get latest release for luci-app-adguardhome"
    return 1
  fi
  
  # 提取版本号和下载URL
  VERSION=$(echo "$LATEST_RELEASE" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
  if [ -z "$VERSION" ]; then
    echo "Failed to extract version from release data"
    return 1
  fi
  
  echo "Found latest version: $VERSION"
  
  # 获取资产列表
  ASSETS=$(echo "$LATEST_RELEASE" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4)
  
  # 查找匹配的资产
  ADGUARD_IPK=$(echo "$ASSETS" | grep "luci-app-adguardhome_.*_all.ipk" | head -1)
  
  # 如果找不到资产，使用构建的URL
  if [ -z "$ADGUARD_IPK" ]; then
    ADGUARD_IPK="https://github.com/rufengsuixing/luci-app-adguardhome/releases/download/$VERSION/luci-app-adguardhome_${VERSION}_all.ipk"
    echo "Warning: Could not find adguardhome asset, using fallback URL"
  fi
  
  # 更新链接
  sed -i "s|https://github.com/rufengsuixing/luci-app-adguardhome/releases/download/.*luci-app-adguardhome_.*_all.ipk|$ADGUARD_IPK|" "$URL_FILE"
  
  echo "Updated AdGuardHome package URL"
}

# 更新 nikki 包
update_nikki_package() {
  echo "Updating nikki package..."
  
  # 获取最新版本
  LATEST_RELEASE=$(curl -s -H "$AUTH_HEADER" "https://api.github.com/repos/nikkinikki-org/OpenWrt-nikki/releases/latest")
  if [ $? -ne 0 ] || [ -z "$LATEST_RELEASE" ]; then
    echo "Failed to get latest release for OpenWrt-nikki"
    return 1
  fi
  
  # 提取版本号
  VERSION=$(echo "$LATEST_RELEASE" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
  if [ -z "$VERSION" ]; then
    echo "Failed to extract version from release data"
    return 1
  fi
  
  echo "Found latest nikki version: $VERSION"
  
  # 构建新的下载链接 - 保持文件名不变，只更新版本
  NIKKI_TAR_URL="https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/$VERSION/nikki_x86_64-openwrt-24.10.tar.gz"
  
  # 更新链接 - 保留 archive: 前缀
  sed -i "s|archive:https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/.*nikki_x86_64-openwrt-24.10.tar.gz|archive:$NIKKI_TAR_URL|" "$URL_FILE"
  
  echo "Updated nikki package URL to: archive:$NIKKI_TAR_URL"
}

# 主函数
main() {
  echo "Updating package URLs in $URL_FILE..."
  
  # 检查是否安装了必要的工具
  for cmd in curl grep sed; do
    if ! command -v $cmd &> /dev/null; then
      echo "Error: $cmd is required but not installed."
      exit 1
    fi
  done
  
  # 检查文件是否存在
  if [ ! -f "$URL_FILE" ]; then
    echo "Error: $URL_FILE does not exist"
    exit 1
  fi
  
  # 更新各个包的链接
  update_lucky_packages
  update_adguardhome_package
  update_nikki_package
  
  echo "All package URLs have been updated"
}

# 执行主函数
main
