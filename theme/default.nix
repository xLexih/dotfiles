{
  lib ? pkgs.lib,
  pkgs ? null,
}: let
  helpers = import ./lib.nix {inherit lib;};
  themeDirs =
    lib.filterAttrs (
      name: type:
        type
        == "directory"
        && builtins.pathExists (./. + "/${name}/default.nix")
    )
    (builtins.readDir ./.);
in {
  default = "hexagon";
  inherit helpers;

  fonts = {
    packages =
      if pkgs == null
      then []
      else
        with pkgs; [
          material-design-icons
          material-symbols
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          jetbrains-mono
          dejavu_fonts
          freefont_ttf
          gyre-fonts
          liberation_ttf
          unifont
        ];

    defaultFonts = {
      serif = ["Noto Serif" "Noto Color Emoji"];
      sansSerif = ["Noto Sans" "Noto Color Emoji"];
      monospace = ["JetBrains Mono" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };

  themes = lib.mapAttrs (name: _:
    import (./. + "/${name}") {
      inherit helpers pkgs;
      inherit lib;
    })
  themeDirs;
}
