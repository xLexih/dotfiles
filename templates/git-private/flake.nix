{
  description = "Private-file hook and git-private tooling";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = {...} @ inputs: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forEachSystem = inputs.nixpkgs.lib.genAttrs systems;
    pkgsFor = system: import inputs.nixpkgs {inherit system;};
  in {
    devShells = forEachSystem (
      system: let
        pkgs = pkgsFor system;
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            age
            bashInteractive
            coreutils
            findutils
            git
            gnugrep
            gnused
            just
            openssh
            shellcheck
          ];

          shellHook = ''
            echo "dev shell: run 'just --list' for available tasks"
          '';
        };
      }
    );

    formatter = forEachSystem (
      system: let
        pkgs = pkgsFor system;
      in
        pkgs.writeShellApplication {
          name = "format-nix";
          runtimeInputs = [pkgs.nixfmt];
          text = ''
            if [ "$#" -eq 0 ]; then
              set -- flake.nix
            fi

            exec nixfmt "$@"
          '';
        }
    );
  };
}
