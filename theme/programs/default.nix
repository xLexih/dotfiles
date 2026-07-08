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

  managedFile = file:
    if lib.isAttrs file && (file ? text || file ? source)
    then {clobber = true;} // file
    else file;

  managedFiles = files:
    lib.mapAttrs (_: managedFile) files;

  mergeProgramAttr = attr:
    lib.foldl'
    (acc: program: acc // (program.${attr} or {}))
    {}
    (builtins.attrValues programs);
in {
  inherit programs;

  homeFiles = managedFiles (mergeProgramAttr "homeFiles");
  xdgConfigFiles = managedFiles (mergeProgramAttr "xdgConfigFiles");
  xdgDataFiles = managedFiles (mergeProgramAttr "xdgDataFiles");
  environmentEtc = mergeProgramAttr "environmentEtc";
}
