{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.import-tree.url = "github:denful/import-tree";

  inputs.hjem.url = "github:feel-co/hjem";
  inputs.hjem.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-index-database.url = "github:nix-community/nix-index-database";
  inputs.nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";

  inputs.nix-cachyos-kernel = {
    url = "github:xddxdd/nix-cachyos-kernel/release";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  inputs.spicetify-nix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix4vscode.url = "github:nix-community/nix4vscode";
  inputs.nix4vscode.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  inputs.nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

  inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {self, ...} @ inputs: let
    inherit (inputs.nixpkgs) lib;

    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = lib.genAttrs systems;
    mkSystem = import (self + "/lib/mkSystem.nix") {inherit inputs;};

    nixosConfigurations = {
      desktop = mkSystem {
        host = "desktop";
        system = "x86_64-linux";
        users = ["lex"];
      };
      laptop = mkSystem {
        host = "laptop";
        system = "x86_64-linux";
        users = ["lex"];
      };
    };
  in {
    formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.alejandra);
    devShells = forAllSystems (
      system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = [pkgs.alejandra];
        };
      }
    );

    templates.git-private = {
      path = ./template/git-private;
      description = "Private-file encryption Git repository template";
    };

    inherit nixosConfigurations;

    checks = import (self + "/lib/checks.nix") {inherit lib inputs self systems;};
  };
}
