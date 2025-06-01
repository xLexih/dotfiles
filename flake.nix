{
  description = "NixOS Flakes Rahhh";
  inputs = {
    
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";
    
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";
  
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = function:
        nixpkgs.lib.genAttrs systems (system:
          function (import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          }));
    in {
      formatter = forAllSystems (pkgs: [pkgs.alejandra]);
      nixosConfigurations = {
        desktop = let
          settings = {
            stateVersion = "25.05";
            system = "x86_64-linux";
            kernal = "linuxPackages_xanmod_latest"; #_xanmod_latest";#"linuxPackages_zen";
            
            hostName = "desktop";
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
