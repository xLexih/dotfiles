# kitty colors, included from kitty.conf. kitty reloads its config on SIGUSR1.
{
  lib,
  pkgs,
  ...
}: {
  modules.theme.render.kitty = theme: let
    c = theme.terminal;
    order = ["black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"];
    ansi = map (name: c.normal.${name}) order ++ map (name: c.bright.${name}) order;
  in {
    ".config/kitty/theme.conf" = ''
      background ${c.background}
      foreground ${c.foreground}
      cursor ${c.cursor}
      cursor_text_color ${c.cursorText}
      selection_background ${c.selectionBg}
      selection_foreground ${c.selectionFg}
      url_color ${c.url}

      active_tab_background ${c.tabActiveBg}
      active_tab_foreground ${c.tabActiveFg}
      inactive_tab_background ${c.tabInactiveBg}
      inactive_tab_foreground ${c.tabInactiveFg}

      ${lib.concatImapStrings (i: color: "color${toString (i - 1)} ${color}\n") ansi}'';
  };

  modules.theme.reload.kitty = "${pkgs.procps}/bin/pkill -USR1 -x kitty";
}
