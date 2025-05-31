{
  description = "NixOS configuration of Ryan Yin";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager.url = "github:nix-community/home-manager/release-24.11";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # hyprland.url = "github:hyprwm/Hyprland";
    # nur.url = "github:nix-community/nur";
    # nur.inputs.nixpkgs.follows = "nixpkgs";
    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      systems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = function:
        nixpkgs.lib.genAttrs systems (system:
          function (import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          }));
    in {
      formatter = forAllSystems (pkgs: pkgs.alejandra);
      nixosConfigurations = {
        desktop = let
          settings = {
            stateVersion = "25.05";
            system = "x86_64-linux";
            kernal = "linuxPackages_zen"; #_xanmod_latest";#"linuxPackages_zen";
            users = [ "lex" ];
          };
          specialArgs = { inherit inputs outputs settings; };
        in nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = settings.system;
          modules = [
            ./users
            ./device/desktop
            ./nixosModules
          ];
        };
      };
    };
}
