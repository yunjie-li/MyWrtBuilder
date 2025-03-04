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

# Function: Update URL in the file
update_url() {
  local pattern="$1"
  local new_url="$2"
  
  echo "Attempting to update URL pattern: $pattern"
  echo "New URL: $new_url"
  
  # Check if pattern exists in file
  if ! grep -q "$pattern" "$URL_FILE"; then
    echo "Warning: Pattern not found in file: $pattern"
    return 1
  fi
  
  # Update the URL
  sed -i "s|$pattern|$new_url|g" "$URL_FILE"
  
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
  
  # Update links - use very specific patterns to avoid conflicts
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/v[^/]*/luci-app-lucky_[^_]*_all.ipk" "$luci_app"
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/v[^/]*/luci-i18n-lucky-zh-cn_[^_]*_all.ipk" "$luci_i18n"
  update_url "https://github.com/gdy666/luci-app-lucky/releases/download/v[^/]*/lucky_[^_]*_Openwrt_x86_64.ipk" "$lucky_x86"
}

# Update luci-app-mosdns related packages
update_mosdns_packages() {
  echo "Updating Mosdns packages..."
  
  # Get latest version
  local release_data=$(get_latest_release "sbwml/luci-app-mosdns")
  [ -z "$release_data" ] && echo "Failed to get latest release for luci-app-mosdns" && return 1
  
  # Extract version number
  local version=$(echo "$release_data" | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
  [ -z "$version" ] && echo "Failed to extract version" && return 1
  
  echo "Found latest version: $version"
  
  # Build download links
  local base_url="https://github.com/sbwml/luci-app-mosdns/releases/download/$version"
  local assets=$(echo "$release_data" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4)
  
  # Find matching assets or use fallbacks
  local mosdns_app=$(echo "$assets" | grep "luci-app-mosdns_.*_all.ipk" | head -1)
  [ -z "$mosdns_app" ] && mosdns_app="$base_url/luci-app-mosdns_${version#v}_all.ipk"
  
  local mosdns_i18n=$(echo "$assets" | grep "luci-i18n-mosdns-zh-cn_*_all.ipk" | head -1)
  [ -z "$mosdns_i18n" ] && mosdns_i18n="$base_url/luci-i18n-mosdns-zh-cn_${version#v}_all.ipk"
  
  local mosdns_x86=$(echo "$assets" | grep "mosdns_*_x86_64.ipk" | head -1)
  [ -z "$mosdns_x86" ] && mosdns_x86="$base_url/mosdns_${version#v}_x86_64.ipk"

  local v2dat_x86=$(echo "$assets" | grep "v2dat_*_x86_64.ipk" | head -1)
  [ -z "$v2dat_x86" ] && v2dat_x86="$base_url/v2dat_${version#v}_x86_64.ipk"
  
  # Update links - use very specific patterns to avoid conflicts
  update_url "https://github.com/sbwml/luci-app-mosdns/releases/download/v[^/]*/luci-app-mosdns_[^_]*_all.ipk" "$mosdns_app"
  update_url "https://github.com/sbwml/luci-app-mosdns/releases/download/v[^/]*/luci-i18n-mosdns-zh-cn_[^_]*_all.ipk" "$mosdns_i18n"
  update_url "https://github.com/sbwml/luci-app-mosdns/releases/download/v[^/]*/mosdns_[^_]*_x86_64.ipk" "$mosdns_x86"
  update_url "https://github.com/sbwml/luci-app-mosdns/releases/download/v[^/]*/mosdns_[^_]*_x86_64.ipk" "$v2dat_x86"
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
  update_url "archive:https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/v[^/]*/nikki_x86_64-openwrt-24.10.tar.gz" "archive:$nikki_tar_url"
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
  
  # Print original content for debugging
  echo "Original content of $URL_FILE:"
  cat "$URL_FILE"
  
  # Update packages - keep them separate to avoid conflicts
  update_lucky_packages
  update_mosdns_packages
  update_nikki_package
  
  echo "All package URLs have been updated"
  echo "Updated content of $URL_FILE:"
  cat "$URL_FILE"
  
  # Commit changes if enabled
  [ "$GIT_COMMIT" = "true" ] && commit_to_git
}

# Run the script
main
