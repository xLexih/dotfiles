{
  description = "NixOS Flakes Rahhh";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";

    # disko.url = "github:nix-community/disko";
    # disko.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix4vscode.url = "github:nix-community/nix4vscode";
    nix4vscode.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    quickshell.url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    hid-send.url = "path:./overlays/hid-send";
    opencode.url = "path:./overlays/opencode";
    kilo.url = "path:./overlays/kilo";
    free-models.url = "path:./overlays/free-coding-models";
    ani-cli.url = "path:./overlays/ani-cli";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";

  defaultOverlay = final: prev: {
    hid-send = inputs.hid-send.packages.${prev.stdenv.hostPlatform.system}.hid-send;
    opencode = inputs.opencode.packages.${prev.stdenv.hostPlatform.system}.default;
    kilo = inputs.kilo.packages.${prev.stdenv.hostPlatform.system}.default;
    free-models = inputs.free-models.packages.${prev.stdenv.hostPlatform.system}.default;
    ani-cli = inputs.ani-cli.packages.${prev.stdenv.hostPlatform.system}.default;
  };

    makeNixosSystem = {
      system,
      modules,
      settings,
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules =
          [
            inputs.nix-index-database.nixosModules.nix-index
            inputs.nix-index-database.nixosModules.default

            {
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [
                  defaultOverlay
                  inputs.nix4vscode.overlays.default
                  inputs.nix-vscode-extensions.overlays.default
                ];
              };
            }
          ]
          ++ modules;
        specialArgs = {
          inherit inputs settings;
        };
      };

    commonSettings = hostName: {
      inherit system;
      inherit hostName;
      stateVersion = "25.11";
      kernel_name = "xanmod_latest";
      users = ["lex"];
    };
  in {
    overlays.default = defaultOverlay;

    formatter =
      (import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }).alejandra;

    nixosConfigurations = {
      desktop = makeNixosSystem {
        inherit system;
        settings = commonSettings "desktop";
        modules = [
          ./users
          ./device/desktop
          ./module
        ];
      };

      laptop = makeNixosSystem {
        inherit system;
        settings = commonSettings "laptop";
        modules = [
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-gpu-nvidia
          ./users
          ./device/laptop
          ./module
        ];
      };
    };
  };
}
