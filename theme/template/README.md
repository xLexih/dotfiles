# Theme Template

Use this directory as the shape reference for adding a theme. It is ignored by
theme discovery, so real themes should live at `theme/<name>/default.nix`.

Minimum structure:

```text
theme/<name>/
├── default.nix
└── outputs.nix
```

`default.nix` owns the theme data:

```nix
{
  helpers,
  lib,
  pkgs ? null,
}: let
  ui = {
    bg = "#000000";
    bgDark = "#000000";
    bgDarker = "#000000";
    surface = "#111111";
    overlay = "#222222";
    fg = "#ffffff";
    fgMuted = "#888888";
    accent = "#88ccff";
    accentAlt = "#66aadd";
    accentBright = "#bce8ff";
    shadow = "#000000";
    red = "#ff6b6b";
    green = "#51cf66";
    yellow = "#ffd43b";
    blue = "#74c0fc";
    cyan = "#66d9e8";
  };

  theme = rec {
    name = "<name>";
    gnomeAccent = "blue";
    inherit ui;

    # Optional semantic roles. Omit this block to use defaults derived from
    # `ui`, or override only the roles that need different contrast.
    roles = {
      selectionBg = ui.accent;
      selectionFg = ui.bgDarker;
      focus = ui.accentBright;
      link = ui.accentAlt;
      border = ui.overlay;
      borderStrong = ui.accentAlt;
      hoverBg = ui.surface;
      activeBg = ui.overlay;
      inputBg = ui.bgDarker;
      accentFg = ui.bgDarker;
    };

    gtk = {
      package = if pkgs == null then null else pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
      preferDark = true;
    };

    icon = {
      package = if pkgs == null then null else pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    cursor = {
      package = if pkgs == null then null else pkgs.bibata-cursors;
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
      colorScheme = "<Name>";
    };

    outputs = import ./outputs.nix {
      inherit helpers lib theme;
    };
  };
in
  theme
```

`outputs.nix` should normally copy `theme/hexagon/outputs.nix`. Shared token
generation lives in `helpers.mkThemeTokens`, and semantic colors are available
through `helpers.mkThemeRoles` / `helpers.mkThemePalette`, so most new themes
only need to change values in `default.nix`.
