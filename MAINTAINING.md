# Maintaining bun-overlay

This document provides guidance on maintaining the bun-overlay project, particularly regarding hash verification and updates.

## Handling Hash Mismatches

If you encounter a hash mismatch error like this:

```
error: hash mismatch in fixed-output derivation '/nix/store/2ww3pxmszxjbxb7vp1x9jm3w4gp2bwqa-bun-linux-aarch64.zip.drv':
         specified: sha256-3FBL13k226bMLUzgj7h8X1IeKGochoz9zYUOxlXv0Ho=
            got:    sha256-yJiiBX+Rm3AL8onYQ9rknuEUyPYlx8H+0EN5D1RpRQk=
```

Follow these steps to resolve it:

1. **Identify the platform and version** - From the error message, determine which platform and Bun version is affected.

2. **Update the hash in sources.json** - Open `sources.json` and update the relevant hash. You need to update both:
   - The version-specific entry (e.g., "1.2.12")
   - The "latest" entry if the affected version is also the latest

3. **Verify the hash** - Run the `verify-hashes.sh` script to verify all hashes across platforms:
   ```bash
   ./verify-hashes.sh
   ```

4. **Test the fix** - Test that the fix works by building for the affected platform:
   ```bash
   # For example, to test on aarch64-linux:
   ssh nixos@your-aarch64-machine 'nix develop github:0xbigboss/bun-overlay -c bun --version'
   ```

## Updating to a New Bun Version

When a new version of Bun is released:

1. **Run the update script** - The `update` script automates fetching new versions and updating hashes:
   ```bash
   # Update to latest
   ./update latest

   # Update to a specific version
   ./update 1.2.13

   # Update canary
   ./update canary
   ```

2. **Verify the hashes** - After updating, verify all hashes:
   ```bash
   ./verify-hashes.sh
   ```

3. **Run tests** - Test building on different platforms:
   ```bash
   ./test-versions.sh
   ```

## Hash Formats

This repository now standardizes on a single hash format:

- **Base64 format with prefix** - Standard format with `sha256-` prefix, e.g.:
  ```
  "sha256-yJiiBX+Rm3AL8onYQ9rknuEUyPYlx8H+0EN5D1RpRQk="
  ```

When updating hashes manually, if you're given a Base64 hash with `sha256-` prefix from an error message, use that format directly.

## Troubleshooting

If you encounter issues:

1. **Verify source URLs** - Check if the release URLs are still valid by visiting them in a browser.

2. **Check release signatures** - Bun releases include signature files that can be verified:
   ```bash
   curl -O https://github.com/oven-sh/bun/releases/download/bun-v1.2.12/SHASUMS256.txt.asc
   gpg --verify SHASUMS256.txt.asc
   ```

3. **Manual hash calculation** - Calculate the hash of a downloaded file:
   ```bash
   # For Nix base32 format:
   nix-hash --type sha256 --flat --base32 path/to/downloaded.zip

   # For Base64 format:
   nix-hash --type sha256 --flat --base64 path/to/downloaded.zip
   ```
