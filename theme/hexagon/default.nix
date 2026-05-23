{
  helpers,
  lib,
  pkgs ? null,
}: let
  ui = {
    bg = "#1a1025";
    bgDark = "#140c1c";
    bgDarker = "#0f0914";
    surface = "#221430";
    overlay = "#2d1d3e";
    fg = "#e4daf0";
    fgMuted = "#887ea0";
    accent = "#c4a0ff";
    accentAlt = "#a88ee0";
    accentBright = "#dfc4ff";
    shadow = "#0a0610";
    red = "#f38ba8";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    blue = "#b4befe";
    cyan = "#94e2d5";
  };

  theme = rec {
    name = "hexagon";

    # closest GNOME preset to ui.accent — controls AccentColor CSS system
    # color via xdg-desktop-portal. valid: blue teal green yellow orange
    # red pink purple slate
    gnomeAccent = "purple";

    gtk = {
      package =
        if pkgs == null
        then null
        else pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
      preferDark = true;
    };

    icon = {
      package =
        if pkgs == null
        then null
        else pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    cursor = {
      package =
        if pkgs == null
        then null
        else pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    font = {
      sans = "Noto Sans 11";
      document = "Noto Sans 11";
      mono = "JetBrains Mono 11";
    };

    qt = {
      platformTheme = "qt5ct";
      style = "kvantum";
      qtctStyle = "kvantum-dark";
      kvantum = "KvArcDark";
      kdeLookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "Hexagon";
    };

    spicetify = {
      theme = {
        name = "hexagon";
        src = ./spicetify;
        injectCss = true;
        injectThemeJs = false;
        replaceColors = true;
        homeConfig = true;
        overwriteAssets = false;
      };
      colorScheme = "hexagon";
    };

    inherit ui;

    kitty = {
      background = ui.bg;
      foreground = ui.fg;
      cursor = ui.accent;
      cursorText = ui.bg;
      selection = ui.overlay;
      selectionFg = ui.fg;
      url = ui.accentAlt;
      tab = {
        activeBg = ui.accent;
        activeFg = ui.bg;
        inactiveBg = ui.surface;
        inactiveFg = ui.fgMuted;
      };
      normal = {
        black = ui.bg;
        red = ui.red;
        green = ui.green;
        yellow = ui.yellow;
        blue = ui.blue;
        magenta = ui.accent;
        cyan = ui.cyan;
        white = ui.fg;
      };
      bright = {
        black = ui.overlay;
        red = ui.red;
        green = ui.green;
        yellow = ui.yellow;
        blue = ui.blue;
        magenta = ui.accentBright;
        cyan = ui.cyan;
        white = "#ffffff";
      };
    };

    outputs = import ./outputs.nix {
      inherit helpers lib theme;
    };
  };
in
  theme
