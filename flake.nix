{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.import-tree.url = "github:denful/import-tree";

  inputs.hjem.url = "github:feel-co/hjem";
  inputs.hjem.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";

  inputs.nix-cachyos-kernel = {
    url = "github:xddxdd/nix-cachyos-kernel/release";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  inputs.spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix4vscode.url = "github:nix-community/nix4vscode";
  inputs.nix4vscode.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  inputs.nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {self, ...} @ inputs: let
    inherit (inputs.nixpkgs) lib;

    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = lib.genAttrs systems;
    mkSystem = import (self + "/lib/mkSystem.nix") {inherit inputs;};

    nixosConfigurations = {
      desktop = mkSystem {
        host = "desktop";
        system = "x86_64-linux";
        users = ["lex"];
      };
      laptop = mkSystem {
        host = "laptop";
        system = "x86_64-linux";
        users = ["lex"];
      };
    };
  in {
    formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.alejandra);

    inherit nixosConfigurations;

    checks = forAllSystems (
      system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        hostConfigs = lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) self.nixosConfigurations;
        evalChecks =
          lib.mapAttrs' (
            name: cfg: let
              drvPath = builtins.unsafeDiscardStringContext cfg.config.system.build.toplevel.drvPath;
            in
              lib.nameValuePair "eval-${name}" (
                pkgs.runCommand "eval-${name}" {} ''
                  printf '%s\n' ${lib.escapeShellArg drvPath} > $out
                ''
              )
          )
          hostConfigs;
        contractChecks =
          lib.mapAttrs' (
            name: cfg:
              lib.nameValuePair "contract-${name}" (
                pkgs.runCommand "contract-${name}" {} ''
                  cat > $out <<EOF
                  hostName=${cfg.config.networking.hostName}
                  stateVersion=${cfg.config.system.stateVersion}
                  cpuVendor=${cfg.config.modules.hardware.cpu.vendor}
                  themeName=${cfg.config.modules.theme.active.name}
                  EOF
                ''
              )
          )
          hostConfigs;
      in
        evalChecks
        // contractChecks
        // {
          formatting =
            pkgs.runCommand "alejandra-check" {
              nativeBuildInputs = with pkgs; [alejandra findutils];
            } ''
              cd ${self}
              find . \
                -path ./.git -prune -o \
                -path ./host/homelab -prune -o \
                -type f -name '*.nix' -print0 \
                | xargs -0 alejandra --check
              touch $out
            '';

          import-tree-hygiene =
            pkgs.runCommand "import-tree-hygiene" {
              nativeBuildInputs = with pkgs; [findutils gnugrep ripgrep];
            } ''
              cd ${self}
              bad=0
              files="$(mktemp)"
              find module host user \
                -path host/homelab -prune -o \
                -path '*/.config' -prune -o \
                -type f -name '*.nix' -print | sort > "$files"

              while IFS= read -r file; do
                base="$(basename "$file")"
                case "$base" in
                  default.nix|_*.nix) continue ;;
                esac

                if ! rg -F --quiet "$base" flake.nix lib module host user overlay theme .config README.md; then
                  echo "Unreferenced Nix file inside import-tree path must be prefixed with '_': $file" >&2
                  bad=1
                fi
              done < "$files"

              test "$bad" -eq 0
              touch $out
            '';
        }
    );
  };
}
