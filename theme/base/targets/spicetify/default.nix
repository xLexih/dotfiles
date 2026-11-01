# Spotify (Spicetify): user.css styles the layout with the theme's
# `spicetify` colors.
#
# Spicetify patches Spotify at build time, which bakes in the default theme's
# color.ini. Every switch also writes the current colors to
# ~/.config/theme/spicetify.css, which the patched Spotify links in after the
# built-in ones (xpui/theme-colors.css), so it starts in the current theme.
# theme.js re-reads that file every 2 seconds and on focus and swaps changed
# colors in, so a running Spotify follows switches too.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (import ../../lib.nix {inherit lib;}) rgbCsv;
  theme = config.modules.theme.themes.${config.modules.theme.default};

  colorIni = lib.generators.toINI {} {
    ${theme.name} = lib.mapAttrs (_: lib.removePrefix "#") theme.spicetify;
  };

  src = pkgs.runCommand "spicetify-theme-${theme.name}" {} ''
    mkdir $out
    cp ${pkgs.writeText "color.ini" colorIni} $out/color.ini
    cp ${./user.css} $out/user.css
    cp ${./theme.js} $out/theme.js
  '';

  # Spotify is one package for the whole system, so it can only link one
  # home's colors; the theme's users are its hjem users.
  home = config.users.users.${lib.head (lib.attrNames config.hjem.users)}.home;
in {
  modules.theme.render.spicetify = t: {
    ".config/theme/spicetify.css" = ''
      :root {
      ${lib.concatStrings (lib.mapAttrsToList (name: value: ''
          --spice-${name}: ${value};
          --spice-rgb-${name}: ${rgbCsv value};
        '')
        t.spicetify)}}
    '';
  };

  programs.spicetify = {
    spotifyPackage = pkgs.spotify.overrideAttrs (old: {
      # Runs after Spicetify's apply, on the patched xpui.
      postFixup =
        (old.postFixup or "")
        + ''
          xpui=$out/share/spotify/Apps/xpui
          ln -s ${home}/.config/theme/spicetify.css $xpui/theme-colors.css
          substituteInPlace $xpui/index.html --replace-fail \
            "<link rel='stylesheet' class='userCSS' href='colors.css'>" \
            "<link rel='stylesheet' class='userCSS' href='colors.css'><link rel='stylesheet' class='userCSS' href='theme-colors.css'>"
        '';
    });
    theme = {
      inherit (theme) name;
      inherit src;
      injectCss = true;
      injectThemeJs = true;
      replaceColors = true;
      homeConfig = true;
      overwriteAssets = false;
    };
    colorScheme = theme.name;
  };
}
