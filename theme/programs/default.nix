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

  programs = {
    firefox = callProgram ./firefox.nix;
    gtk = callProgram ./gtk.nix;
    hyprland = callProgram ./hyprland.nix;
    kitty = callProgram ./kitty.nix;
    palette = callProgram ./palette.nix;
    qt = callProgram ./qt.nix;
  };

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
