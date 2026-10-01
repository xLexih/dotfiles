# On-screen display for volume and brightness (swayosd, GTK 4 CSS). The
# server reads the style sheet at startup, so a switch restarts it.
{
  lib,
  pkgs,
  ...
}: let
  inherit (import ../../lib.nix {inherit lib;}) gtkColors;
in {
  modules.theme = {
    render.swayosd = theme: {
      ".config/swayosd/style.css" = gtkColors "theme" theme.colors + "\n" + builtins.readFile ./style.css;
    };
    reload.swayosd = "${pkgs.systemd}/bin/systemctl --user try-restart swayosd.service";
  };
}
