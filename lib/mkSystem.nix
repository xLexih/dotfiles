{inputs}: {
  host,
  system,
  users ? [],
}: let
  filteredImportTree = path: (inputs.import-tree.matchNot ".*/\\.config/.*") path;

  userEnableModule = {lib, ...}: {
    config = lib.mkMerge (map (user: {
        modules.user.${user}.enable = true;
      })
      users);
  };
in
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit host inputs users;
    };
    modules =
      [
        {
          nixpkgs = {
            config.allowUnfree = true;
            overlays =
              [
                inputs.nix-index-database.overlays.nix-index
              ]
              ++ (import (inputs.self + "/overlay"))
              ++ [
                inputs.nix4vscode.overlays.default
                inputs.nix-vscode-extensions.overlays.default
              ];
          };
        }
        inputs.hjem.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        (import (inputs.self + "/theme/module.nix"))
        (filteredImportTree (inputs.self + "/module"))
        (filteredImportTree (inputs.self + "/host/${host}"))
        userEnableModule
      ]
      ++ map (user: filteredImportTree (inputs.self + "/user/${user}")) users;
  }
