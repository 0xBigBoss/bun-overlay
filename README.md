# Bun Nix Flake Overlay

This repository provides a Nix flake overlay for [Bun](https://bun.sh), a fast all-in-one JavaScript runtime, bundler, test runner and package manager. The flake packages the pre-built binary releases from the official Bun repository.

## Features

- Packages Bun runtime and package manager
- Downloads pre-built binaries directly from official releases
- Verifies binary signatures using Bun's official GPG key
- Automatically selects appropriate binary for systems without AVX2 support
- Works on multiple platforms: Linux (x86_64, aarch64) and macOS (Intel/Apple Silicon)
- Properly handles dynamic linking on NixOS and other Linux distributions
- Provides a convenient development shell with Bun pre-configured

## Usage

### As a Flake (Recommended)

In your `flake.nix` file:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    bun-overlay.url = "github:0xbigboss/bun-overlay";
  };

  outputs = { self, nixpkgs, bun-overlay, ... }:
    let
      system = "x86_64-linux"; # or x86_64-darwin, aarch64-darwin, aarch64-linux
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ bun-overlay.overlays.default ];
      };
    in {
      # Use Bun in your packages
      packages.default = pkgs.mkShell {
        buildInputs = [
          pkgs.bun
        ];
      };
    };
}
```

### Command Line Usage

```sh
# Install and run bun (latest version)
$ nix run github:0xbigboss/bun-overlay#bun

# Open a shell with Bun available
$ nix develop github:0xbigboss/bun-overlay

# Build Bun
$ nix build github:0xbigboss/bun-overlay#bun

# Use Bun within your shell
$ nix shell github:0xbigboss/bun-overlay#bun
```

### Non-Flake Usage (Legacy Nix)

If you're not using flakes, you can still use this package through the `default.nix` compatibility layer:

```nix
let
  bunOverlay = import (fetchTarball "https://github.com/0xbigboss/bun-overlay/archive/main.tar.gz");
  pkgs = import <nixpkgs> { overlays = [ bunOverlay ]; };
in pkgs.mkShell {
  buildInputs = [ pkgs.bun ];
}
```

## Available Packages and Outputs

The flake provides the following outputs:

- `packages.<s>.bun`: The Bun JavaScript runtime and package manager
- `packages.<s>.default`: Same as `bun`

- `apps.<s>.bun`: Run the `bun` command
- `apps.<s>.default`: Run the `bun` command

- `devShells.<s>.default`: A development shell with Bun

- `overlays.default`: An overlay that adds Bun packages to nixpkgs

## Templates

This flake provides the following templates:

### Bun Template

A basic Bun project template for JavaScript/TypeScript development:

```sh
# Create a new project using the Bun template
$ mkdir my-bun-project
$ cd my-bun-project
$ nix flake init -t github:0xbigboss/bun-overlay#init
```

The template includes:
- Nix configuration with Bun available
- Direnv integration for automatic environment loading

After initializing the template:

```sh
# Enter the development environment
$ nix develop

# Create a new Bun project
$ bun init
```

## Updating to New Versions

### Automatic Updates

The flake includes an update script to fetch the latest Bun versions and update all hashes:

```sh
# Update to the latest version
$ ./update latest

# Update to a specific version
$ ./update 1.2.13

# Update canary builds
$ ./update canary
```

### Manual Updates

You can also manually update the flake to use new Bun versions by:

1. Updating the SHA256 hashes in `sources.json` for each platform
2. Updating the version information

### Verifying Hashes

To verify the hashes across all platforms, run:

```sh
$ ./verify-hashes.sh
```

### Handling Hash Mismatches

If you encounter hash mismatches during builds, refer to the [MAINTAINING.md](./MAINTAINING.md) document for solutions.

## Version Selection

This flake supports multiple Bun versions:

### Latest Releases

By default, the flake uses the "latest" release. This is the recommended version for most users.

### Canary Builds

The flake also supports "canary" builds. To use the canary version:

```sh
# Using environment variable with nix-build (legacy)
$ BUN_VERSION=canary nix-build

# Using environment variable with flakes (requires --impure flag)
$ BUN_VERSION=canary nix develop --impure
$ BUN_VERSION=canary nix run --impure .#bun
$ BUN_VERSION=canary nix build --impure .#bun

# Using command-line argument with nix-build (legacy)
$ nix-build --argstr bunVersion canary
```

### Specific Versions

You can pin to specific versions by adding them to `sources.json` and then selecting them:

```sh
# Using environment variable with nix-build (legacy)
$ BUN_VERSION=1.2.12 nix-build

# Using environment variable with flakes (requires --impure flag)
$ BUN_VERSION=1.2.12 nix develop --impure
$ BUN_VERSION=1.2.12 nix build --impure .#bun

# Using command-line argument with nix-build (legacy)
$ nix-build --argstr bunVersion 1.2.12
```

### Version Selection Precedence

The version selection follows this precedence:
1. Command-line argument (when using `nix-build --argstr bunVersion "version"`)
2. Environment variable `BUN_VERSION`
3. Default to "latest" if neither is specified

## AVX2 Support

For x86_64 Linux systems without AVX2 support, this flake automatically selects the baseline binary variant. This is handled via the `stdenv.hostPlatform.avx2Support` property in Nix.

## Security

This flake ensures binary integrity through cryptographic hash verification:

1. All binary packages are fetched using Nix's `fetchurl` function with explicit SHA-256 hashes
2. These hashes are maintained in the `sources.json` file for each platform and version
3. When updating to new Bun versions, the update script (`./update`) performs full GPG verification:
   - Bun's official GPG key (`F3DCC08A8572C0749B3E18888EAB4D40A7B22B59`) is imported from a keyserver
   - The signed `SHASUMS256.txt.asc` file is downloaded and its signature is verified
   - The SHA-256 checksums of downloaded archives are verified against the verified `SHASUMS256.txt`
   - The verified hashes are then stored in `sources.json` for reliable builds

This approach balances security and reliability:
- Strong security during updates when the GPG key servers are accessible
- Reliable builds using pre-verified hashes during normal usage
- No runtime dependency on external GPG key servers during builds
- Consistent build behavior in air-gapped or restricted network environments

## Development

### Testing the Flake

To test that the flake is working correctly:

```sh
# Run the comprehensive test script
$ ./test-versions.sh

# Or run individual tests:

# Check the flake structure
$ nix flake check

# Build the bun package
$ nix build .#bun

# Test the binary
$ ./result/bin/bun --version

# Test the development shell
$ nix develop
$ bun --version
```

### Platform Compatibility

The flake is designed to work on all supported platforms:

- **Linux (x86_64)**: Includes proper dynamic linking support for NixOS and other Linux distributions using `autoPatchelfHook` and required runtime dependencies. Special handling for systems without AVX2 support.
- **Linux (aarch64)**: Supports ARM64 Linux systems.
- **macOS (Intel/Apple Silicon)**: Works with native macOS binaries without additional dependencies.

If you encounter any platform-specific issues, please report them in the GitHub issues.

## License

This flake is released under the MIT License. Bun itself is developed by [Oven](https://github.com/oven-sh/bun) and is released under the MIT License.
