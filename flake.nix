{
  description = "NixOS configuration of Ryan Yin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: {
    nixosConfigurations = {
      desktop = let
        username = "lex";
        specialArgs = {inherit username;};
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
        };
        lib = pkgs.lib;
        config = {}; # or your actual config if any
      in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          inherit system;
          modules = [
            ./device/desktop
            ./user/${username}/nixos.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = inputs // specialArgs;
              home-manager.users.lex = import ./device/desktop/home.nix {
                 inherit config pkgs username lib;
              };
            }
          ];
        };
    };
  };
}
