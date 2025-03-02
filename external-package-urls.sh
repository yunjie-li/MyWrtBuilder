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
if [ -n "$GITHUB_TOKEN" ]; then
  AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
fi

# Function: Get latest release information
get_latest_release() {
  local repo="$1"
  curl -s -H "$AUTH_HEADER" "https://api.github.com/repos/$repo/releases/latest"
}

# Function: Update URL in the file with more precise pattern matching
update_url() {
  local pattern="$1"
  local new_url="$2"
  
  # Debug output
  echo "Attempting to update URL pattern: $pattern"
  echo "New URL: $new_url"
  
  # Check if pattern exists in file
  if ! grep -q "$pattern" "$URL_FILE"; then
    echo "Warning: Pattern not found in file: $pattern"
    echo "Current file content:"
    cat "$URL_FILE"
    return 1
  fi
  
  # Use more specific sed pattern with word boundaries where appropriate
  sed -i "s|$pattern|$new_url|g" "$URL_FILE"
  
  # Verify the change was made
  if grep -q "$new_url" "$URL_FILE"; then
    echo "URL successfully updated to: $new_url"
  else
    echo "Failed to update URL. Pattern may not have matched exactly."
    echo "Current file content after attempted update:"
    cat "$URL_FILE"
  fi
}

# Function: Add or update URL in the file
add_or_update_url() {
  local pattern="$1"
  local new_url="$2"
  local url_type="$3"  # Simple pattern to identify URL type (e.g., "adguardhome", "fileassistant")
  
  # Check if a URL of this type already exists in the file
  if grep -q "$url_type" "$URL_FILE"; then
    echo "Updating existing $url_type URL"
    sed -i "s|https://[^[:space:]]*$url_type[^[:space:]]*|$new_url|g" "$URL_FILE"
  else
    echo "Adding new $url_type URL to file"
    # Add before the archive section if it exists
    if grep -q "^# 压缩包" "$URL_FILE"; then
      sed -i "/^# 压缩包/i $new_url" "$URL_FILE"
    else
      # Otherwise just append to the end
      echo "$new_url" >> "$URL_FILE"
    fi
  fi
  
  # Verify the change was made
  if grep -q "$new_url" "$URL_FILE"; then
    echo "URL successfully added/updated to: $new_url"
  else
    echo "Failed to add/update URL."
    echo "Current file content after attempted update:"
    cat "$URL_FILE"
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
  
  # Update links with more specific patterns
  sed -i "s|https://github.com/gdy666/luci-app-lucky/releases/download/.*/luci-app-lucky_.*_all.ipk|$luci_app|g" "$URL_FILE"
  sed -i "s|https://github.com/gdy666/luci-app-lucky/releases/download/.*/luci-i18n-lucky-zh-cn_.*_all.ipk|$luci_i18n|g" "$URL_FILE"
  sed -i "s|https://github.com/gdy666/luci-app-lucky/releases/download/.*/lucky_.*_Openwrt_x86_64.ipk|$lucky_x86|g" "$URL_FILE"
  
  echo "Lucky package URLs updated"
}

# Update luci-app-adguardhome package
update_adguardhome_package() {
  echo "Updating luci-app-adguardhome package..."
  
  # Get the latest version from the website
  local html_content=$(curl -s "https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/")
  
  # Extract the latest luci-app-adguardhome package name using grep and sed
  local latest_package=$(echo "$html_content" | grep -o "luci-app-adguardhome_[^\"]*_all.ipk" | head -1)
  
  if [ -z "$latest_package" ]; then
    echo "Warning: Could not find latest luci-app-adguardhome package, using fallback pattern"
    # Use a generic URL pattern that will match any version
    latest_package="luci-app-adguardhome_*_all.ipk"
  fi
  
  # Build the full URL
  local adguardhome_url="https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/$latest_package"
  
  echo "Found luci-app-adguardhome package: $latest_package"
  
  # Use the new add_or_update_url function
  add_or_update_url "luci-app-adguardhome_.*_all.ipk" "$adguardhome_url" "luci-app-adguardhome"
  
  echo "luci-app-adguardhome package URL updated to $adguardhome_url"
}

# Update adguardhome binary package
update_adguardhome_binary() {
  echo "Updating AdGuardHome binary package..."
  
  # Get the latest version from the website
  local html_content=$(curl -s "https://dl.openwrt.ai/releases/24.10/packages/x86_64/packages/")
  
  # Extract the latest adguardhome package name using grep and sed
  local latest_package=$(echo "$html_content" | grep -o "adguardhome_[^\"]*x86_64.ipk" | head -1)
  
  if [ -z "$latest_package" ]; then
    echo "Warning: Could not find latest adguardhome binary package, using fallback pattern"
    # Use a generic URL pattern that will match any version
    latest_package="adguardhome_*x86_64.ipk"
  fi
  
  # Build the full URL
  local adguardhome_binary_url="https://dl.openwrt.ai/releases/24.10/packages/x86_64/packages/$latest_package"
  
  echo "Found adguardhome binary package: $latest_package"
  
  # Use the new add_or_update_url function
  add_or_update_url "adguardhome_.*x86_64.ipk" "$adguardhome_binary_url" "adguardhome"
  
  echo "AdGuardHome binary package URL updated to $adguardhome_binary_url"
}

# Update luci-app-fileassistant package
update_fileassistant_package() {
  echo "Updating luci-app-fileassistant package..."
  
  # Get the latest version from the website
  local html_content=$(curl -s "https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/")
  
  # Extract the latest luci-app-fileassistant package name using grep and sed
  local latest_package=$(echo "$html_content" | grep -o "luci-app-fileassistant_[^\"]*_all.ipk" | head -1)
  
  if [ -z "$latest_package" ]; then
    echo "Warning: Could not find latest luci-app-fileassistant package, using fallback pattern"
    # Use a generic URL pattern that will match any version
    latest_package="luci-app-fileassistant_*_all.ipk"
  fi
  
  # Build the full URL
  local fileassistant_url="https://dl.openwrt.ai/packages-24.10/x86_64/kiddin9/$latest_package"
  
  echo "Found luci-app-fileassistant package: $latest_package"
  
  # Use the new add_or_update_url function
  add_or_update_url "luci-app-fileassistant_.*_all.ipk" "$fileassistant_url" "luci-app-fileassistant"
  
  echo "luci-app-fileassistant package URL updated to $fileassistant_url"
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
  
  # Update link - preserve archive: prefix with more specific pattern
  sed -i "s|archive:https://github.com/nikkinikki-org/OpenWrt-nikki/releases/download/.*/nikki_x86_64-openwrt-24.10.tar.gz|archive:$nikki_tar_url|g" "$URL_FILE"
  
  echo "Nikki package URL updated to: archive:$nikki_tar_url"
}

# Function to commit changes to Git repository
commit_to_git() {
  # Check if git is available
  if ! command -v git &> /dev/null; then
    echo "Git not found, skipping commit."
    return 1
  fi
  
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Not in a Git repository, skipping commit."
    return 1
  fi
  
  echo "Committing changes to Git..."
  
  # Configure Git if in CI environment
  if [ -n "$CI" ]; then
    git config --global user.name "URL Update Bot"
    git config --global user.email "bot@example.com"
  fi
  
  # Add the file
  git add "$URL_FILE"
  
  # Check if there are changes to commit
  if git diff --cached --quiet; then
    echo "No changes to commit."
    return 0
  fi
  
  # Commit the changes
  git commit -m "$COMMIT_MESSAGE"
  echo "Changes committed successfully."
  
  # Push if enabled
  if [ "$GIT_PUSH" = "true" ]; then
    echo "Pushing changes to remote repository..."
    git push
    echo "Changes pushed successfully."
  else
    echo "Changes committed but not pushed. Use 'git push' to push changes."
  fi
  
  return 0
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
  
  # Make a backup of the original file
  cp "$URL_FILE" "${URL_FILE}.bak"
  echo "Backup created at ${URL_FILE}.bak"
  
  # Print original content for debugging
  echo "Original content of $URL_FILE:"
  cat "$URL_FILE"
  
  # Update package links
  update_lucky_packages
  update_adguardhome_package
  update_adguardhome_binary
  update_fileassistant_package
  update_nikki_package
  
  echo "All package URLs have been updated"
  echo "Updated content of $URL_FILE:"
  cat "$URL_FILE"
  
  # Display file information for debugging
  echo "File path: $(realpath $URL_FILE)"
  echo "File exists: $(test -f $URL_FILE && echo 'Yes'
