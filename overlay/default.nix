{lib}: let
  ignoredFiles = [
    "default.nix"
    "codium.nix"
  ];

  overlayFiles = lib.sort builtins.lessThan (
    builtins.attrNames (
      lib.filterAttrs (
        name: type:
          type
          == "regular"
          && lib.hasSuffix ".nix" name
          && !(builtins.elem name ignoredFiles)
      )
      (builtins.readDir ./.)
    )
  );
in
  map (name: import (./. + "/${name}")) overlayFiles
