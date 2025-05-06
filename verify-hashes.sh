#!/usr/bin/env bash
set -euo pipefail

# Function to download a file and get its hash
get_file_hash() {
  local url=$1
  local tmp_file
  tmp_file=$(mktemp)
  
  curl -s -L -o "$tmp_file" "$url"
  
  # Get the Nix-compatible hash
  local hash
  hash=$(nix-hash --type sha256 --flat --base64 "$tmp_file")
  
  # Clean up
  rm "$tmp_file"
  
  echo "$hash"
}

# Check sources.json
if [[ ! -f sources.json ]]; then
  echo "Error: sources.json not found"
  exit 1
fi

# Parse JSON and verify hashes
echo "Verifying hashes in sources.json..."

# Function to verify a specific version
verify_version() {
  local version=$1
  echo "Checking version: $version"
  
  # Get the tag from sources.json
  tag=$(jq -r ".[\"$version\"].tag" sources.json)
  echo "Release tag: $tag"
  
  # Check each platform
  platforms=("aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" "x86_64-linux-baseline")
  
  for platform in "${platforms[@]}"; do
    echo "Checking platform: $platform..."
    
    # Get the URL and expected hash from sources.json
    url=$(jq -r ".[\"$version\"].platforms[\"$platform\"].url" sources.json)
    expected_hash=$(jq -r ".[\"$version\"].platforms[\"$platform\"].sha256" sources.json)
    
    # Skip if the platform doesn't exist in the JSON
    if [[ "$url" == "null" ]]; then
      echo "  Skipping platform $platform (not found in sources.json)"
      continue
    fi
    
    # Download and get the actual hash
    echo "  URL: $url"
    echo "  Expected hash: $expected_hash"
    
    # If the expected hash doesn't start with sha256-, assume it's old format
    if [[ ! "$expected_hash" == sha256-* ]]; then
      echo "  Note: Hash is in old format, skipping direct comparison"
      continue
    fi
    
    # Compare actual hash with expected hash
    local actual_hash
    echo "  Downloading and checking hash..."
    actual_hash=$(get_file_hash "$url")
    echo "  Actual hash:   sha256-$actual_hash"
    
    if [[ "sha256-$actual_hash" == "$expected_hash" ]]; then
      echo "  ✅ Hashes match!"
    else
      echo "  ❌ Hash mismatch!"
      echo "     - Expected: $expected_hash"
      echo "     - Actual:   sha256-$actual_hash"
    fi
    
    echo ""
  done
}

# Verify each version
echo "Verifying latest version..."
verify_version "latest"

echo "Verifying canary version..."
verify_version "canary"

# Get all specific versions (excluding latest and canary)
specific_versions=$(jq -r 'keys[] | select(. != "latest" and . != "canary")' sources.json)

# Verify each specific version
for version in $specific_versions; do
  verify_version "$version"
done

echo "Hash verification complete!"