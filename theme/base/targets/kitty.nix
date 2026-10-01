# kitty colors, included from kitty.conf. Also switchable live with theme-switch.
{
  config,
  lib,
  ...
}: let
  render = theme: let
    c = theme.terminal;
  in ''
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

    ${lib.concatImapStrings (i: color: "color${toString (i - 1)} ${color}\n") (ansiColors c)}'';

  ansiColors = c: let
    order = ["black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"];
  in
    map (name: c.normal.${name}) order ++ map (name: c.bright.${name}) order;
in {
  modules.theme.live.".config/kitty/theme.conf" = render;
  dotfiles.files.".config/kitty/theme.conf" = render config.modules.theme.active;
}
