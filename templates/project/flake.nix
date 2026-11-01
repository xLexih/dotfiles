{
  description = "project";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.age
            pkgs.git
            pkgs.just
            pkgs.shellcheck
            pkgs.ssh-to-age # ed25519 ssh keys as age keys, for script/private
          ];
        };

        formatter = pkgs.alejandra;
      }
    );
}
