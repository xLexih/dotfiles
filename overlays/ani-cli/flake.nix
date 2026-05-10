{
  description = "ani-cli - A cli to browse and watch anime";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        version = "4.13";

        ani-cli = pkgs.ani-cli.overrideAttrs (old: rec {
          inherit version;
          src = pkgs.fetchFromGitHub {
            owner = "pystardust";
            repo = "ani-cli";
            tag = "v${version}";
            hash = "sha256-R+sXA5NZ/gDElMUTUHyOha7ZZ6FKgwTpAYuWUF4hqto=";
          };
        });
      in {
        packages.default = ani-cli;

        apps.default = {
          type = "app";
          program = "${ani-cli}/bin/ani-cli";
        };

        devShells.default = pkgs.mkShell {
          packages = [ani-cli];
        };
      }
    );
}
