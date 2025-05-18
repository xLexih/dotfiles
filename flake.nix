{
  description = "NixOS configuration of Ryan Yin";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";

  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    ...
  }: {
    nixosConfigurations = {
      desktop = let
        username = "lex";
        stateVersion = "24.11";
        system = "x86_64-linux";
        specialArgs = {inherit username system stateVersion;}; # Pass in variables, that other things MIGHT use.
      in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          inherit system;
          modules = [
            ./device/desktop
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = inputs // specialArgs;

              home-manager.users.lex = import ./device/desktop/home.nix;
            }
          ];
        };
    };
  };
}
