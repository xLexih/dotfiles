{
  description = "NixOS configuration of Ryan Yin";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    nur.url = "github:nix-community/nur";
    nur.inputs.nixpkgs.follows = "nixpkgs";
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
            stateVersion = "24.11";
            system = "x86_64-linux";
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
            # inputs.nur.modules.nixos.default
            # inputs.home-manager.nixosModules.home-manager
            # {
            #   nixpkgs.config.allowUnfree = true; # <--- Add this here!
            #   #              home-manager.backupFileExtension = "backup";
            #   home-manager.backupFileExtension =
            #     "backup-"; # + nixpkgs.lib.readFile (nixpkgs.runCommand "timestamp" {} ''date '+%Y%m%d%H%M%S'` > $out'');
            #   home-manager.useGlobalPkgs = false;
            #   home-manager.useUserPackages = true;
            #   home-manager.extraSpecialArgs = inputs // specialArgs;

            #   home-manager.users.lex = import ./device/desktop/home.nix;
            # }
          ];
        };
      };
    };
}
