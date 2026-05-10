{
  description = "Kilo Code CLI for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      nodejs = pkgs.nodejs_24;

      fhs = pkgs.buildFHSEnv {
        name = "free-models";

        targetPkgs = p: [
          nodejs
          p.coreutils
          p.bash
          p.stdenv.cc.cc.lib
          p.glibc
          p.zlib
          p.openssl
          p.icu
          p.libgcc
        ];

        runScript = pkgs.writeShellScript "free-models-inner" ''
          export PATH="${nodejs}/bin:$PATH"
          VERSION="0.1.66"
          MODEL_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/free-models-cli"
          BIN_PATH="$MODEL_DIR/node_modules/.bin/free-coding-models"
          if [ ! -f "$BIN_PATH" ]; then
            echo "First run: installing free-coding-models@$VERSION to $MODEL_DIR"
            mkdir -p "$MODEL_DIR"
            npm install --prefix "$MODEL_DIR" "free-coding-models@$VERSION"
          fi

          exec "$BIN_PATH" "$@"
        '';
      };
    in {
      packages.default = fhs;

      apps.default = {
        type = "app";
        program = "${fhs}/bin/free-models";
      };

      devShells.default = pkgs.mkShell {
        packages = [fhs];
      };
    });
}
