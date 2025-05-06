{
  pkgs ? import <nixpkgs> {},
  system ? builtins.currentSystem,
  bunVersion ? null,
}: let
  inherit (pkgs) lib;
  sources = builtins.fromJSON (lib.strings.fileContents ./sources.json);

  # Define target version with the following precedence:
  # 1. Explicitly provided bunVersion parameter
  # 2. BUN_VERSION environment variable
  # 3. Default to "latest"
  envVersion = builtins.getEnv "BUN_VERSION";
  selectedVersion =
    if bunVersion != null
    then bunVersion
    else if envVersion != ""
    then envVersion
    else "latest";

  # Access relevant data from sources.json
  # This handles either "latest", "canary", or specific version tags
  versionData =
    if builtins.hasAttr selectedVersion sources
    then sources.${selectedVersion}
    else throw "Bun version '${selectedVersion}' not found in sources.json";

  # Create a base derivation for fetching bun binary
  mkBunPackage = {
    version,
    pname ? "bun",
  }: let
    # Check if the platform supports AVX2
    hasAvx2 = pkgs.stdenv.hostPlatform.avx2Support;

    # Select appropriate platform data based on system architecture and AVX2 support
    platformData =
      if system == "x86_64-linux" && !hasAvx2
      then versionData.platforms."x86_64-linux-baseline"
      else versionData.platforms.${system} or (throw "Unsupported system: ${system}");

    # Create a derivation for fetching the archive
    bun-archive = pkgs.fetchurl {
      url = platformData.url;
      sha256 = platformData.sha256;
    };

    # Platform-specific details

    # Get platform name for reference
    getPlatformNameForShasum = platform: let
      mapping = {
        "aarch64-darwin" = "darwin-aarch64";
        "aarch64-linux" = "linux-aarch64";
        "x86_64-darwin" = "darwin-x64";
        "x86_64-linux" = "linux-x64";
        "x86_64-linux-baseline" = "linux-x64-baseline";
      };
    in "bun-${mapping.${platform}}.zip";

    platformFilename = getPlatformNameForShasum system;
  in
    pkgs.stdenv.mkDerivation {
      inherit version;
      pname = pname;

      src = bun-archive;

      # Add required tools and runtime dependencies
      nativeBuildInputs =
        (lib.optionals pkgs.stdenv.isLinux [
          pkgs.autoPatchelfHook
        ])
        ++ [
          pkgs.unzip
        ];

      # Add required runtime dependencies for Linux platforms
      # Based on Docker implementation, we only need minimal libraries
      buildInputs = lib.optionals pkgs.stdenv.isLinux [
        pkgs.stdenv.cc.cc.lib # libstdc++
        pkgs.glibc # GNU libc compatibility
      ];

      dontBuild = true;
      dontPatch = true;
      dontConfigure = true;

      # Extract the archive and install files
      installPhase = ''
        # Just copy the source archive for reference
        cp $src ./${platformFilename}

        # Now extract and install the binary
        mkdir -p $out/bin

        # Create a temp directory and extract the zip archive
        mkdir -p ./temp
        ${pkgs.unzip}/bin/unzip $src -d ./temp

        # Find and move the bun binary
        find ./temp -type f -name "bun" -exec cp {} $out/bin/bun \;

        # Make sure it's executable
        chmod +x $out/bin/bun

        # Create symlinks for bun subcommands
        ln -s $out/bin/bun $out/bin/bunx
      '';

      meta = {
        description = "Bun is a fast JavaScript runtime, package manager, bundler and test runner";
        homepage = "https://bun.sh";
        license = pkgs.lib.licenses.mit;
        platforms = pkgs.lib.platforms.unix;
      };
    };

  # Create the bun package
  bun = mkBunPackage {
    version = versionData.version;
  };
in {
  inherit bun;
  default = bun;
}
