# The resolved theme for scripts and the bar: ~/.config/theme/palette.json
# (watched by Quickshell, so the bar recolors right away) and a sourceable
# palette.sh (THEME_BG, THEME_SELECTION_BG, ..., PROMPT_COLOR) for new shells.
{
  config,
  lib,
  ...
}: let
  inherit (import ../lib.nix {inherit lib;}) rgb;

  envName = name:
    "THEME_"
    + lib.toUpper (lib.concatStrings (map (char:
      if char != lib.toLower char
      then "_" + char
      else char) (lib.stringToCharacters name)));
in {
  modules.theme.render.palette = theme: let
    accent = rgb theme.palette.accent;
    variables =
      {
        THEME_NAME = theme.name;
        THEME_VARIANT = theme.variant;
        PROMPT_COLOR = "38;2;${toString accent.r};${toString accent.g};${toString accent.b}m";
      }
      // lib.mapAttrs' (name: value: lib.nameValuePair (envName name) value) (theme.palette // theme.roles);
  in {
    ".config/theme/palette.json" = builtins.toJSON (config.modules.theme.describe theme);
    ".config/theme/palette.sh" = lib.concatLines (lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") variables);
  };
}
