{
  description = "Bun runtime, package manager, and bundler.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";

    # Used for shell.nix
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    systems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin" "aarch64-linux"];
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      # Import packages from default.nix
      # Prioritize bunVersion from the BUN_VERSION environment variable if set
      # Note: builtins.trace is used for debugging here, will show the selected version in build output
      envVersion = builtins.getEnv "BUN_VERSION";
      selectedVersion =
        if envVersion != ""
        then envVersion
        else null;
      bunPkgs = import ./default.nix {
        inherit pkgs system;
        bunVersion = selectedVersion;
      };
    in rec {
      # The packages exported by the Flake
      packages = bunPkgs;

      # "Apps" so that `nix run` works
      apps = {
        bun = flake-utils.lib.mkApp {
          drv = packages.bun;
          name = "bun";
        };
        default = apps.bun;
      };

      # nix fmt
      formatter = pkgs.alejandra;

      # Development shell with bun
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          packages.bun
        ];
      };

      # For compatibility with older versions of the `nix` binary
      devShell = self.devShells.${system}.default;
    });
  in
    outputs
    // {
      # Overlay that can be imported so you can access the packages
      overlays.default = final: prev: {
        bunPackages = outputs.packages.${prev.system};
        bun = outputs.packages.${prev.system}.bun;
      };

      templates.init = {
        path = ./templates/init;
        description = "A basic Bun development environment.";
      };
    };
}
