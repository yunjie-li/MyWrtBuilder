#!/bin/bash
set -e

# Configuration
URL_FILE="external-package-urls.txt"
GITHUB_TOKEN=${GITHUB_TOKEN:-""}
AUTH_HEADER=""
GIT_COMMIT=${GIT_COMMIT:-"true"}  
GIT_PUSH=${GIT_PUSH:-"true"}    
COMMIT_MESSAGE="Update package URLs to latest versions"

# Add GitHub token to request header if available
[ -n "$GITHUB_TOKEN" ] && AUTH_HEADER="Authorization: token $GITHUB_TOKEN"

# Function: Get latest release information
get_latest_release() {
  curl -s -H "$AUTH_HEADER" "https://api.github.com/repos/$1/releases/latest"
}

# Function: Add or update URL in the file
update_url() {
  local pattern="$1"
  local new_url="$2"
  local url_type="${3:-}"
  
  echo "Updating URL: $new_url"
  
  if [ -n "$url_type" ] && grep -q "$url_type" "$URL_FILE"; then
    # Update existing URL of this type
    sed -i "s|https://[^[:space:]]*$url_type[^[:space:]]*|$new_url|g" "$URL_FILE"
  else
    # Update by pattern or add new
    if grep -q "$pattern" "$URL_FILE"; then
      sed -i "s|$pattern|$new_url|g" "$URL_FILE"
    else
      # Add new URL before archive section or at the end
      if grep -q "^# 压缩包" "$URL_FILE"; then
        sed -i "/^# 压缩包/i $new_url" "$URL_FILE"
      else
        echo "$new_url" >> "$URL_FILE"
      fi
    fi
  fi
  
  # Verify the change was made
  if grep -q "$new_url" "$URL_FILE"; then
    echo "URL successfully updated to: $new_url"
  else
    echo "Failed to update URL."
  fi
}

# Update luci-app-lucky related packages
update_lucky_packages() {
  echo "Updating Lucky packages..."
  
  # Get latest version
  local release_data=$(get_latest_release "gdy666/luci-app-lucky")
  [ -z "$release_data" ] && echo "Failed to get latest release for luci-app-lucky" && return 1
  
  # Extract version number
  local version=$(echo "$release_data" | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
  [ -z "$version" ] && echo "Failed to extract version" && return 1
  
  echo "Found latest version: $version"
  
  # Build download links
  local base_url="https://github.com/gdy666/luci-app-lucky/releases/download/$version"
  local assets=$(echo "$release_data" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4)
  
  # Find matching assets or use fallbacks
  local luci_app=$(echo "$assets" | grep "luci-app-lucky_.*_all.ipk" | head -1)
  [ -z "$luci_app" ] && luci_app="$base_url/luci-app-lucky_${version#v}_all.ipk"
  
  local luci_i18n=$(echo "$assets" | grep "luci-i18n-lucky-zh-cn_.*_all.ipk" | head -1)
  [ -z "$luci_i18n" ] && luci_i18n="$base_url/luci-i18n-lucky-zh-cn_${version#v}_all.ipk"
  
  local lucky_x86=$(echo "$assets" | grep "lucky_.*_Openwrt_x86_64.ipk" | head -1)
  [ -z "$lucky_x86" ] && lucky_x86="$base_url/lucky_${version#v}_Openwrt_x86_64.ipk"
  
  # Update links
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/.*/luci-app-lucky_.*_all.ipk" "$luci_app"
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/.*/luci-i18n-lucky-zh-cn_.*_all.ipk" "$luci_i18n"
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/.*/lucky_.*_Openwrt_x86_64.ipk" "$lucky_x86"
}

# Update packages from openwrt.ai
update_openwrt_ai_packages() {
  echo "Updating packages from openwrt.ai..."
  
  # Update luci-app-adguardhome
  local html_content=$(curl -s "https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/")
  local adguardhome_pkg=$(echo "$html_content" | grep -o "luci-app-adguardhome_[^\"]*_all.ipk" | head -1)
  [ -n "$adguardhome_pkg" ] && update_url "luci-app-adguardhome_.*_all.ipk" \
    "https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/$adguardhome_pkg" "luci-app-adguardhome"
  
  # Update adguardhome binary
  html_content=$(curl -s "https://dl.openwrt.ai/releases/24.10/packages/x86_64/packages/")
  local adguardhome_bin=$(echo "$html_content" | grep -o "adguardhome_[^\"]*x86_64.ipk" | head -1)
  [ -n "$adguardhome_bin" ] && update_url "adguardhome_.*x86_64.ipk" \
    "https://dl.openwrt.ai/releases/24.10/packages/x86_64/packages/$adguardhome_bin" "adguardhome"
  
  # Update luci-app-fileassistant
  html_content=$(curl -s "https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/")
  local fileassistant_pkg=$(echo "$html_content" | grep -o "luci-app-fileassistant_[^\"]*_all.ipk" | head -1)
  [ -n "$fileassistant_pkg" ] && update_url "luci-app-fileassistant_.*_all.ipk" \
    "https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/$fileassistant_pkg" "luci-app-fileassistant"
}

# Update nikki package
update_nikki_package() {
  echo "Updating Nikki package..."
  
  local release_data=$(get_latest_release "nikkinikki-org/OpenWrt-nikki")
  [ -z "$release_data" ] && echo "Failed to get latest release for OpenWrt-nikki" && return 1
  
  local version=$(echo "$release_data" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
  [ -z "$version" ] && echo "Failed to extract version" && return 1
  
  echo "Found latest version: $version"
  
  local nikki_tar_url="https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/$version/nikki_x86_64-openwrt-24.10.tar.gz"
  update_url "archive:https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/.*/nikki_x86_64-openwrt-24.10.tar.gz" "archive:$nikki_tar_url"
}

# Function to commit changes to Git repository
commit_to_git() {
  # Skip if git not available or not in a git repo
  if ! command -v git &> /dev/null || ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Git not available or not in a Git repository, skipping commit."
    return 1
  fi
  
  echo "Committing changes to Git..."
  
  # Configure Git if in CI environment
  [ -n "$CI" ] && git config --global user.name "URL Update Bot" && git config --global user.email "bot@example.com"
  
  # Add the file and check for changes
  git add "$URL_FILE"
  if git diff --cached --quiet; then
    echo "No changes to commit."
    return 0
  fi
  
  # Commit and optionally push
  git commit -m "$COMMIT_MESSAGE"
  echo "Changes committed successfully."
  
  if [ "$GIT_PUSH" = "true" ]; then
    echo "Pushing changes to remote repository..."
    git push
    echo "Changes pushed successfully."
  fi
  
  return 0
}

# Main function
main() {
  echo "Updating package URLs in $URL_FILE..."
  
  # Check requirements
  for cmd in curl grep sed; do
    command -v $cmd &> /dev/null || { echo "Error: $cmd is required but not installed."; exit 1; }
  done
  
  # Check if file exists
  [ ! -f "$URL_FILE" ] && echo "Error: $URL_FILE does not exist" && exit 1
  
  # Make a backup
  cp "$URL_FILE" "${URL_FILE}.bak"
  echo "Backup created at ${URL_FILE}.bak"
  
  # Update packages
  update_lucky_packages
  update_openwrt_ai_packages
  update_nikki_package
  
  echo "All package URLs have been updated"
  
  # Commit changes if enabled
  [ "$GIT_COMMIT" = "true" ] && commit_to_git
}

# Run the script
main
