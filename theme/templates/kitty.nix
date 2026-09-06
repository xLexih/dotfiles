{
  ui,
  roles,
}: {
  background = ui.bg;
  foreground = ui.fg;
  cursor = roles.focus;
  cursorText = ui.bg;
  selection = roles.selectionBg;
  selectionFg = roles.selectionFg;
  url = roles.link;
  tab = {
    activeBg = roles.selectionBg;
    activeFg = roles.selectionFg;
    inactiveBg = roles.panelBgAlt;
    inactiveFg = roles.disabledFg;
  };
  normal = {
    black = ui.overlay;
    red = ui.red;
    green = ui.green;
    yellow = ui.yellow;
    blue = ui.blue;
    magenta = ui.accent;
    cyan = ui.cyan;
    white = ui.fg;
  };
  bright = {
    black = roles.disabledFg;
    red = ui.red;
    green = ui.green;
    yellow = ui.yellow;
    blue = ui.blue;
    magenta = roles.focus;
    cyan = ui.cyan;
    white = ui.fg;
  };
}
