# Screenshot annotation (satty): the theme's colors as the quick palette.
{lib, ...}: {
  modules.theme.render.satty = theme: let
    p = theme.colors;
    font = (import ../lib.nix {inherit lib;}).parseFont theme.fonts.sans;
    palette = map (color: ''"${color}ff"'') [p.accent p.red p.yellow p.green p.cyan p.blue p.fg];
  in {
    ".config/satty/config.toml" = ''
      [general]
      early-exit = true
      floating-hack = true
      no-window-decoration = true
      corner-roundness = 12
      initial-tool = "arrow"
      copy-command = "wl-copy"
      output-filename = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png"
      actions-on-enter = ["save-to-clipboard"]
      actions-on-escape = ["exit"]

      [font]
      family = "${font.family}"

      [color-palette]
      palette = [${lib.concatStringsSep ", " palette}]
    '';
  };
}
