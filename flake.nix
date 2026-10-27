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
    # Not following nixpkgs: upstream CI binaries (cachix) match only its
    # locked nixpkgs, and following would rebuild tg_owt + AyuGram (~2800
    # objects) from source on every nixpkgs bump.
    ayugram-desktop.url = "github:ndfined-crp/ayugram-desktop";
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
        users = cfg.config.hjem.users;
        hypr = lib.mapAttrs (_: user: user.files.".config/hypr/hyprland.lua".text or null) users;
        quickshell = lib.mapAttrs (_: user: lib.filterAttrs (path: _: lib.hasPrefix ".config/quickshell/" path) user.files) users;
      in
        {
          "eval-${host}" = pkgs.writeText "eval-${host}" (builtins.unsafeDiscardStringContext cfg.config.system.build.toplevel.drvPath);
          # Checks modules add to the system build (e.g. theme-check).
          "system-${host}" = pkgs.linkFarmFromDrvs "system-checks-${host}" cfg.config.system.checks;
        }
        // lib.mapAttrs' (user: text:
          lib.nameValuePair "hyprland-${host}-${user}" (pkgs.runCommand "hyprland-${host}-${user}" {} ''
            ${pkgs.lua}/bin/luac -p ${pkgs.writeText "hyprland.lua" (builtins.unsafeDiscardStringContext text)}
            touch $out
          ''))
        (lib.filterAttrs (_: text: text != null) hypr)
        # The bar's QML as installed: syntax errors and imports that don't
        # resolve fail; style warnings don't.
        // lib.mapAttrs' (user: files:
          lib.nameValuePair "quickshell-${host}-${user}" (pkgs.runCommand "quickshell-${host}-${user}" {
              config = pkgs.linkFarm "quickshell-${user}" (lib.mapAttrs' (path: file:
                lib.nameValuePair (lib.removePrefix ".config/quickshell/" path) (pkgs.writeText (baseNameOf path) file.text))
              files);
            } ''
              cp -rL $config qml
              cd qml
              imports=$(sed -n 's/^AdditionalImportPaths=//p' .qmllint.ini | tr -d ' ' | tr ',' '\n' | sed 's/^/-I/')
              # qmllint ignores the qmldir next to a linted file, so singletons
              # declared there (asset/qmldir) are passed in explicitly.
              qmldirs=$(find -L . -name qmldir | sed 's/^/-i /')
              ${cfg.pkgs.qt6.qtdeclarative}/bin/qmllint $imports $qmldirs $(find -L . -name '*.qml') >$TMPDIR/lint 2>&1 || { cat $TMPDIR/lint; exit 1; }
              if grep '\[import\]' $TMPDIR/lint; then exit 1; fi
              touch $out
            ''))
        (lib.filterAttrs (_: files: files != {}) quickshell))
      self.nixosConfigurations;
  };
}
