{ui, ...}: {
  cursor = ui.accent;
  selection = ui.overlay;
  selectionFg = ui.fg;
  tab = {
    activeBg = ui.accent;
    activeFg = ui.bg;
    inactiveBg = ui.surface;
  };
  normal = {
    black = ui.fg;
  };
  bright = {
    black = ui.fgMuted;
    white = "#ffffff";
  };
}
