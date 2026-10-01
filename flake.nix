{
  description = "lex's NixOS hosts, users and dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Every host gets global/, modules/ and theme/base; host and user
    # directories are added on top. home/ directories are dotfile layers,
    # not modules.
    mkHost = host: {users}:
      lib.nixosSystem {
        specialArgs = {inherit inputs host users;};
        modules = [
          ((inputs.import-tree.matchNot ".*/home/.*") (
            [./global ./modules ./hosts/${host}] ++ map (user: ./users/${user}) users
          ))
          ./theme/base
        ];
      };

    ownPackages = lib.packagesFromDirectoryRecursive {
      inherit (pkgs) callPackage;
      directory = ./pkgs;
    };
  in {
    nixosConfigurations = lib.mapAttrs mkHost {
      desktop.users = ["lex"];
      laptop.users = ["lex"];
    };

    packages.${system} = removeAttrs ownPackages ["omp-extensions"] // lib.filterAttrs (_: lib.isDerivation) ownPackages.omp-extensions;

    templates.git-private = {
      path = ./templates/git-private;
      description = "Git repository with age-encrypted private files";
    };

    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.alejandra pkgs.lua];
    };

    checks.${system} =
      self.packages.${system}
      // {
        formatting = pkgs.runCommand "alejandra-check" {} ''
          ${lib.getExe pkgs.alejandra} --check ${self}
          touch $out
        '';
      }
      // lib.concatMapAttrs (host: cfg: let
        hypr = lib.mapAttrs (_: user: user.files.".config/hypr/hyprland.lua".text or null) cfg.config.hjem.users;
      in
        {
          "eval-${host}" = pkgs.writeText "eval-${host}" (builtins.unsafeDiscardStringContext cfg.config.system.build.toplevel.drvPath);
        }
        // lib.mapAttrs' (user: text:
          lib.nameValuePair "hyprland-${host}-${user}" (pkgs.runCommand "hyprland-${host}-${user}" {} ''
            ${pkgs.lua}/bin/luac -p ${pkgs.writeText "hyprland.lua" (builtins.unsafeDiscardStringContext text)}
            touch $out
          ''))
        (lib.filterAttrs (_: text: text != null) hypr))
      self.nixosConfigurations;
  };
}
