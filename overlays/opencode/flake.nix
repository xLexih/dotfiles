{
  description = "OpenCode AI coding agent overlay for NixOS";

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

        version = "1.4.6";

        opencode = pkgs.opencode.overrideAttrs (old: rec {
          inherit version;
          src = pkgs.fetchFromGitHub {
            owner = "anomalyco";
            repo = "opencode";
            tag = "v${version}";
            hash = "sha256-u3OeU+3Y/O6KEeDiOl+pswBZ7++kMqwoK+ams03qWE4=";
          };
          node_modules = old.node_modules.overrideAttrs (nmOld: {
            inherit src;
            outputHash = "sha256-atufNVv1pxdcz9TGhlZsQSwZ8E8dxJ7syPA/FD/cZWI=";
          });
        });
      in {
        packages.default = opencode;

        apps.default = {
          type = "app";
          program = "${opencode}/bin/opencode";
        };

        devShells.default = pkgs.mkShell {
          packages = [opencode];
        };
      }
    );
}
