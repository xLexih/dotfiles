# nixpkgs overlays for every host: flake inputs, the packages in pkgs/, then
# every other file in this directory (each one a plain `final: prev:` overlay).
inputs: let
  inherit (inputs.nixpkgs) lib;
  local = lib.filterAttrs (name: type: type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name) (builtins.readDir ./.);
in
  [
    inputs.nix-cachyos-kernel.overlays.pinned
    (final: _: {llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};})
    inputs.nix-vscode-extensions.overlays.default
    (final: _:
      lib.packagesFromDirectoryRecursive {
        inherit (final) callPackage;
        directory = ../pkgs;
      })
  ]
  ++ map (name: import ./${name}) (lib.attrNames local)
