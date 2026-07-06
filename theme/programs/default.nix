{
  lib,
  pkgs,
  sharePickerBinary,
  theme,
}: let
  callProgram = file:
    import file {
      inherit lib pkgs sharePickerBinary theme;
    };

  programFiles =
    lib.filterAttrs (
      name: type:
        type
        == "regular"
        && name != "default.nix"
        && lib.hasSuffix ".nix" name
    )
    (builtins.readDir ./.);

  programs =
    lib.mapAttrs' (
      name: _:
        lib.nameValuePair
        (lib.removeSuffix ".nix" name)
        (callProgram (./. + "/${name}"))
    )
    programFiles;

  mergeProgramAttr = attr:
    lib.foldl'
    (acc: program: acc // (program.${attr} or {}))
    {}
    (builtins.attrValues programs);
in {
  inherit programs;

  homeFiles = mergeProgramAttr "homeFiles";
  xdgConfigFiles = mergeProgramAttr "xdgConfigFiles";
  xdgDataFiles = mergeProgramAttr "xdgDataFiles";
  environmentEtc = mergeProgramAttr "environmentEtc";
}
