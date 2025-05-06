#!/usr/bin/env bash
set -euo pipefail

echo "Testing version selection..."

# Verify hashes first
if [[ -f "./verify-hashes.sh" ]]; then
  echo -e "\n\nVerifying hashes across all platforms..."
  ./verify-hashes.sh
fi

# Test default (latest) version
echo -e "\n\nTesting default (latest) version:"
LATEST_PATH=$(nix-build --no-out-link)
echo "Built at: $LATEST_PATH"
$LATEST_PATH/bin/bun --version

# Test canary version with command-line parameter
echo -e "\n\nTesting canary version via command-line parameter:"
CANARY_PATH=$(nix-build --no-out-link --argstr bunVersion "canary")
echo "Built at: $CANARY_PATH"
$CANARY_PATH/bin/bun --version

# Test specific version with command-line parameter
echo -e "\n\nTesting specific version (1.2.12) via command-line parameter:"
SPECIFIC_PATH=$(nix-build --no-out-link --argstr bunVersion "1.2.12")
echo "Built at: $SPECIFIC_PATH"
$SPECIFIC_PATH/bin/bun --version

# Test with environment variable
echo -e "\n\nTesting canary version via environment variable:"
ENV_PATH=$(BUN_VERSION=canary nix-build --no-out-link)
echo "Built at: $ENV_PATH"
$ENV_PATH/bin/bun --version

echo -e "\n\nAll tests completed!"