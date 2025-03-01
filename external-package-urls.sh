#!/bin/bash
set -e

# Configuration
URL_FILE="external-package-urls.txt"
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
AUTH_HEADER=""

# Add GitHub token to request header if available
if [ -n "$GITHUB_TOKEN" ]; then
  AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
fi

# Function: Get latest release information
get_latest_release() {
  local repo="$1"
  curl -s -H "$AUTH_HEADER" "https://api.github.com/repos/$repo/releases/latest"
}

# Function: Update URL in the file
update_url() {
  local pattern="$1"
  local new_url="$2"
  local category="$3"  # 新参数：URL 类别（普通包或压缩包）
  
  # 检查模式是否存在于文件中
  if grep -q "$pattern" "$URL_FILE"; then
    # 如果存在，替换它
    sed -i "s|$pattern|$new_url|" "$URL_FILE"
    echo "Updated existing URL: $new_url"
  else
    # 如果不存在，添加它到适当的部分
    if [ "$category" = "archive" ]; then
      # 检查压缩包部分是否存在
      if ! grep -q "# 压缩包" "$URL_FILE"; then
        # 如果不存在，添加部分标题
        echo -e "\n# 压缩包 (需要解压提取 IPK 文件)" >> "$URL_FILE"
      fi
      # 添加到压缩包部分
      echo "$new_url" >> "$URL_FILE"
    else
      # 检查普通包部分是否存在
      if ! grep -q "# 普通 IPK 包" "$URL_FILE"; then
        # 如果不存在，添加部分标题
        echo -e "# 普通 IPK 包 (直接下载)" > "$URL_FILE"
      fi
      # 添加到普通包部分（在压缩包部分之前）
      if grep -q "# 压缩包" "$URL_FILE"; then
        # 如果压缩包部分存在，在其前面插入
        sed -i "/# 压缩包/i $new_url" "$URL_FILE"
      else
        # 否则直接添加到文件末尾
        echo "$new_url" >> "$URL_FILE"
      fi
    fi
    echo "Added new URL: $new_url"
  fi
}

# Update luci-app-lucky related packages
update_lucky_packages() {
  echo "Updating Lucky packages..."
  
  # Get latest version
  local release_data=$(get_latest_release "gdy666/luci-app-lucky")
  if [ -z "$release_data" ]; then
    echo "Failed to get latest release for luci-app-lucky"
    return 1
  fi
  
  # Extract version number
  local version=$(echo "$release_data" | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
  if [ -z "$version" ]; then
    echo "Failed to extract version"
    return 1
  fi
  
  echo "Found latest version: $version"
  
  # Build download links
  local base_url="https://github.com/gdy666/luci-app-lucky/releases/download/$version"
  
  # Get assets list
  local assets=$(echo "$release_data" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4)
  
  # Find matching assets
  local luci_app=$(echo "$assets" | grep "luci-app-lucky_.*_all.ipk" | head -1)
  local luci_i18n=$(echo "$assets" | grep "luci-i18n-lucky-zh-cn_.*_all.ipk" | head -1)
  local lucky_x86=$(echo "$assets" | grep "lucky_.*_Openwrt_x86_64.ipk" | head -1)
  
  # Use found assets or build URLs
  if [ -z "$luci_app" ]; then
    luci_app="$base_url/luci-app-lucky_${version#v}_all.ipk"
    echo "Warning: Could not find luci-app-lucky asset, using fallback URL"
  fi
  
  if [ -z "$luci_i18n" ]; then
    luci_i18n="$base_url/luci-i18n-lucky-zh-cn_${version#v}_all.ipk"
    echo "Warning: Could not find luci-i18n-lucky asset, using fallback URL"
  fi
  
  if [ -z "$lucky_x86" ]; then
    lucky_x86="$base_url/lucky_${version#v}_Openwrt_x86_64.ipk"
    echo "Warning: Could not find lucky_x86_64 asset, using fallback URL"
  fi
  
  # Update links
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/.*luci-app-lucky_.*_all.ipk" "$luci_app" "normal"
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/.*luci-i18n-lucky-zh-cn_.*_all.ipk" "$luci_i18n" "normal"
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/.*lucky_.*_Openwrt_x86_64.ipk" "$lucky_x86" "normal"
  
  echo "Lucky package URLs updated"
}

# Update adguardhome package
update_adguardhome_package() {
  echo "Updating AdGuardHome package..."
  
  # Get latest version
  local release_data=$(get_latest_release "rufengsuixing/luci-app-adguardhome")
  if [ -z "$release_data" ]; then
    echo "Failed to get latest release for luci-app-adguardhome"
    return 1
  fi
  
  # Extract version number
  local version=$(echo "$release_data" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
  if [ -z "$version" ]; then
    echo "Failed to extract version"
    return 1
  fi
  
  echo "Found latest version: $version"
  
  # Get assets list
  local assets=$(echo "$release_data" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4)
  
  # Find matching asset
  local adguard_ipk=$(echo "$assets" | grep "luci-app-adguardhome_.*_all.ipk" | head -1)
  
  # Use found asset or build URL
  if [ -z "$adguard_ipk" ]; then
    adguard_ipk="https://github.com/rufengsuixing/luci-app-adguardhome/releases/download/$version/luci-app-adguardhome_${version}_all.ipk"
    echo "Warning: Could not find adguardhome asset, using fallback URL"
  fi
  
  # Update link
  update_url "https://github.com/rufengsuixing/luci-app-adguardhome/releases/download/.*luci-app-adguardhome_.*_all.ipk" "$adguard_ipk" "normal"
  
  echo "AdGuardHome package URL updated"
}

# Update nikki package
update_nikki_package() {
  echo "Updating Nikki package..."
  
  # Get latest version
  local release_data=$(get_latest_release "nikkinikki-org/OpenWrt-nikki")
  if [ -z "$release_data" ]; then
    echo "Failed to get latest release for OpenWrt-nikki"
    return 1
  fi
  
  # Extract version number
  local version=$(echo "$release_data" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
  if [ -z "$version" ]; then
    echo "Failed to extract version"
    return 1
  fi
  
  echo "Found latest version: $version"
  
  # Build new download link - keep filename unchanged, only update version
  local nikki_tar_url="https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/$version/nikki_x86_64-openwrt-24.10.tar.gz"
  
  # Update link - preserve archive: prefix
  update_url "archive:https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/.*nikki_x86_64-openwrt-24.10.tar.gz" "archive:$nikki_tar_url" "archive"
  
  echo "Nikki package URL updated to: archive:$nikki_tar_url"
}

# Main function
main() {
  echo "Updating package URLs in $URL_FILE..."
  
  # Check if required tools are installed
  for cmd in curl grep sed; do
    if ! command -v $cmd &> /dev/null; then
      echo "Error: $cmd is required but not installed."
      exit 1
    fi
  done
  
  # Check if file exists
  if [ ! -f "$URL_FILE" ]; then
    echo "Error: $URL_FILE does not exist"
    exit 1
  fi
  
  # Create file with basic structure if it's empty
  if [ ! -s "$URL_FILE" ]; then
    echo "# 普通 IPK 包 (直接下载)" > "$URL_FILE"
    echo -e "\n# 压缩包 (需要解压提取 IPK 文件)" >> "$URL_FILE"
    echo "Created basic structure in empty file"
  fi
  
  # Update package links
  update_lucky_packages
  update_adguardhome_package
  update_nikki_package
  
  echo "All package URLs have been updated"
  echo "Updated content of $URL_FILE:"
  cat "$URL_FILE"
}

# Execute main function
main
