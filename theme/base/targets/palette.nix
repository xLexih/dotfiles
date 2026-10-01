# The resolved theme for scripts: ~/.config/theme/palette.json and a sourceable
# palette.sh (THEME_BG, THEME_SELECTION_BG, ..., plus PROMPT_COLOR for bash).
{
  config,
  lib,
  ...
}: let
  inherit (import ../lib.nix {inherit lib;}) rgb;

  theme = config.modules.theme.active;
  colors = theme.palette // theme.roles;

  envName = name:
    "THEME_"
    + lib.toUpper (lib.concatStrings (map (char:
      if char != lib.toLower char
      then "_" + char
      else char) (lib.stringToCharacters name)));

  accent = rgb theme.palette.accent;
  variables =
    {
      THEME_NAME = theme.name;
      THEME_VARIANT = theme.variant;
      PROMPT_COLOR = "38;2;${toString accent.r};${toString accent.g};${toString accent.b}m";
    }
    // lib.mapAttrs' (name: value: lib.nameValuePair (envName name) value) colors;
in {
  dotfiles.files = {
    ".config/theme/palette.json" = builtins.toJSON {
      inherit (theme) name variant palette roles terminal;
      gtk = theme.gtk.name;
      icons = theme.icons.name;
      cursor = {inherit (theme.cursor) name size;};
      fonts = theme.fonts;
    };
    ".config/theme/palette.sh" = lib.concatLines (lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") variables);
  };
}
