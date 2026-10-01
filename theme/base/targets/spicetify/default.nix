# Spotify (Spicetify): user.css styles the layout using the theme's
# `spicetify` colors, which become color.ini.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Spicetify patches Spotify at build time, so Spotify keeps the default theme.
  theme = config.modules.theme.themes.${config.modules.theme.default};

  colorIni = lib.generators.toINI {} {
    ${theme.name} = lib.mapAttrs (_: lib.removePrefix "#") theme.spicetify;
  };

  src = pkgs.runCommand "spicetify-theme-${theme.name}" {} ''
    mkdir $out
    cp ${pkgs.writeText "color.ini" colorIni} $out/color.ini
    cp ${./user.css} $out/user.css
  '';
in {
  programs.spicetify = {
    theme = {
      inherit (theme) name;
      inherit src;
      injectCss = true;
      injectThemeJs = false;
      replaceColors = true;
      homeConfig = true;
      overwriteAssets = false;
    };
    colorScheme = theme.name;
  };
}
