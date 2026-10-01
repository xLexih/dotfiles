# Light counterpart of hexagon: warm paper with violet accents.
{config, ...}: let
  p = config.palette;
in {
  variant = "light";
  gnomeAccent = "purple";

  palette = {
    bg = "#faf7f1";
    bgDark = "#efe9dc";
    bgDarker = "#e2d9c6";
    surface = "#fffdf7";
    overlay = "#d8cfbc";
    fg = "#2b2440";
    fgMuted = "#6e6486";
    accent = "#7c3aed";
    accentAlt = "#0e7490";
    accentBright = "#6d28d9";
    shadow = "#d5cbb6";
    red = "#dc2626";
    green = "#15803d";
    yellow = "#92600a";
    blue = "#2563eb";
    cyan = "#0891b2";
  };

  terminal = {
    cursor = p.accent;
    selectionBg = p.overlay;
    selectionFg = p.fg;
    tabActiveBg = p.accent;
    tabActiveFg = p.bg;
    tabInactiveBg = p.surface;
    normal.black = p.fg;
    bright.black = p.fgMuted;
    bright.white = "#ffffff";
  };
}
