{
  helpers,
  lib,
  pkgs ? null,
}: let
  base = import ../hexagon {inherit helpers lib pkgs;};

  ui = {
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

  roles = helpers.mkThemeRoles {inherit ui;};

  apps = {
    kitty = helpers.resolveAppSlots (import ../templates/kitty.nix {inherit ui roles;}) (import ./apps/kitty.nix {inherit ui roles;});
  };

  theme =
    base
    // {
      name = "hexagon-light";
      inherit ui roles apps;
      gtk =
        base.gtk
        // {
          name = "adw-gtk3";
          preferDark = false;
        };
      qt =
        base.qt
        // {
          qtctStyle = "kvantum";
          kvantum = "KvArc";
          kdeLookAndFeel = "org.kde.breeze.desktop";
          colorScheme = "HexagonLight";
        };
    };
in
  theme
  // {
    outputs = import ../hexagon/outputs.nix {inherit helpers lib theme;};
  }
