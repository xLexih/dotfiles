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
  roles = helpers.mkThemeRoles {inherit ui;};

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

    inherit ui roles;

    apps = {
      kitty = helpers.resolveAppSlots (import ../templates/kitty.nix {inherit ui roles;}) (import ./apps/kitty.nix {inherit ui roles;});
    };

    outputs = import ./outputs.nix {
      inherit helpers lib theme;
    };
  };
in
  theme
