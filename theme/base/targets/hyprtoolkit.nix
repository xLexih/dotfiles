# Hyprland's own GUI toolkit (hyprpolkitagent's password dialog). Without an
# icon theme it guesses one from ~/.local/share/icons/default, a cursor theme.
# The agent reads the file at startup, so a switch restarts it.
{
  lib,
  pkgs,
  ...
}: {
  modules.theme = {
    render.hyprtoolkit = theme: let
      c = theme.colors;
      color = hex: "0xff${lib.removePrefix "#" hex}";
      font = (import ../lib.nix {inherit lib;}).parseFont theme.fonts.sans;
    in {
      ".config/hypr/hyprtoolkit.conf" = ''
        background = ${color c.bg}
        base = ${color c.bgDark}
        alternate_base = ${color c.surface}
        text = ${color c.fg}
        bright_text = ${color c.accentBright}
        link_text = ${color c.link}
        accent = ${color c.accent}
        accent_secondary = ${color c.accentAlt}
        icon_theme = ${theme.icons.name}
        font_family = ${font.family}
      '';
    };
    reload.hyprtoolkit = "${pkgs.systemd}/bin/systemctl --user try-restart hyprpolkitagent.service";
  };
}
