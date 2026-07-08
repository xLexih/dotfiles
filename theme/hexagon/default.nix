{
  helpers,
  lib,
  pkgs ? null,
}: let
  ui = {
    bg = "#1a1024";
    bgDark = "#130c1b";
    bgDarker = "#0d0812";
    surface = "#251735";
    overlay = "#38274d";
    fg = "#eee6f8";
    fgMuted = "#b0a4c8";
    accent = "#c6a0ff";
    accentAlt = "#8bd5ca";
    accentBright = "#e2c7ff";
    shadow = "#08050d";
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

    roles = {
      activeBg = ui.overlay;
      activeFg = ui.fg;
      accentFg = ui.bgDarker;
      border = ui.overlay;
      borderStrong = ui.accentAlt;
      dangerFg = ui.bgDarker;
      disabledFg = ui.fgMuted;
      focus = ui.accentBright;
      hoverBg = ui.surface;
      inputBg = ui.bgDarker;
      link = ui.accentAlt;
      panelBg = ui.bg;
      panelBgAlt = ui.bgDark;
      selectionBg = ui.accent;
      selectionFg = ui.bgDarker;
      successFg = ui.bgDarker;
      warningFg = ui.bgDarker;
    };

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
        black = ui.fgMuted;
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
