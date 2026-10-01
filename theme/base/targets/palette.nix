# ~/.config/theme/palette.sh for shells and scripts: THEME_NAME,
# THEME_VARIANT, THEME_<COLOR> (THEME_BG, THEME_SELECTION_BG, ...) and
# PROMPT_COLOR. Programs that read JSON use ~/.config/theme/theme.json, which
# `theme` installs next to it.
{lib, ...}: let
  inherit (import ../lib.nix {inherit lib;}) kebab rgb;

  envName = name: "THEME_" + lib.toUpper (lib.replaceStrings ["-"] ["_"] (kebab name));
in {
  modules.theme.render.palette = theme: let
    accent = rgb theme.colors.accent;
    variables =
      {
        THEME_NAME = theme.name;
        THEME_VARIANT = theme.variant;
        PROMPT_COLOR = "38;2;${toString accent.r};${toString accent.g};${toString accent.b}m";
      }
      // lib.mapAttrs' (name: lib.nameValuePair (envName name)) theme.colors;
  in {
    ".config/theme/palette.sh" = lib.concatLines (lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") variables);
  };
}
