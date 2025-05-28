# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix flake overlay that packages Bun (JavaScript runtime) for multiple platforms by downloading pre-built binaries from official releases. The overlay supports Linux (x86_64/aarch64) and macOS (Intel/Apple Silicon).

## Key Architecture

The project structure:
- **flake.nix**: Main entry point that provides packages, apps, devShells, and overlays. Supports version selection via `BUN_VERSION` environment variable.
- **default.nix**: Core packaging logic that handles platform detection, AVX2 support for x86_64 Linux, and uses `autoPatchelfHook` for Linux dynamic linking.
- **sources.json**: Database of download URLs and SHA256 hashes for each platform and version (latest, canary, and specific releases).

## Common Commands

### Build and Test
```bash
# Build Bun package
nix build .#bun

# Test the built binary
./result/bin/bun --version

# Run comprehensive tests for all versions
./test-versions.sh

# Verify all hashes in sources.json
./verify-hashes.sh
```

### Update Bun Versions
```bash
# Update to latest stable release
./update latest

# Update to specific version
./update 1.2.13

# Update canary build
./update canary
```

### Development
```bash
# Enter development shell
nix develop

# Run Bun directly
nix run .#bun

# Check flake structure
nix flake check
```

### Version Selection
```bash
# Use specific version with environment variable (requires --impure)
BUN_VERSION=canary nix develop --impure
BUN_VERSION=1.2.12 nix build --impure .#bun

# Legacy nix-build with version argument
nix-build --argstr bunVersion canary
```

## Update Process

The `update` script:
1. Downloads Bun releases and verifies GPG signatures using Bun's official key (`F3DCC08A8572C0749B3E18888EAB4D40A7B22B59`)
2. Computes Nix hashes for all platforms
3. Updates `sources.json` with new URLs and hashes

## Hash Management

When encountering hash mismatches:
1. The error message provides the correct hash in `sha256-` base64 format
2. Update the relevant entries in `sources.json` (both version-specific and "latest" if applicable)
3. Run `./verify-hashes.sh` to confirm all hashes are correct
4. Test with `./test-versions.sh`

## Platform Specifics

- **x86_64 Linux**: Automatically detects AVX2 support and selects appropriate binary variant
- **All Linux**: Uses `autoPatchelfHook` to handle dynamic linking with required dependencies
- **macOS**: Uses native binaries without additional dependencies