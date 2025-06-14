{
  description = "NixOS Flakes Rahhh";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";

    # firefox.url = "github:nix-community/flake-firefox-nightly";
    # firefox.inputs.nixpkgs.follows = "nixpkgs";
    # hypr-dynamic-cursors.url = "github:VirtCode/hypr-dynamic-cursors";
    # hypr-dynamic-cursors.inputs.nixpkgs.follows = "hyprland";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = function:
      nixpkgs.lib.genAttrs systems (system:
        function (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));
  in {
    formatter = forAllSystems (pkgs: [pkgs.alejandra]);
    # formatter = forAllSystems (pkgs: [pkgs.treefmtEval]);
    nixosConfigurations = {
      desktop = let
        settings = {
          stateVersion = "25.05";
          system = "x86_64-linux";
          kernal = "linuxPackages_xanmod_latest"; #_xanmod_latest";#"linuxPackages_zen";

          hostName = "desktop";
          users = ["lex"];
        };
        specialArgs = {inherit inputs outputs settings;};
      in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = settings.system;
          modules = [
            ./users
            ./device/desktop
            ./module
          ];
        };
    };
  };
}
