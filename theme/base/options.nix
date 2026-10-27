# Everything a named theme can set. Only `palette` is required; every other
# value is derived from it or from `variant` and can be overridden per theme.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (import ./lib.nix {inherit lib;}) titleCase;

  color = types.strMatching "#[0-9a-fA-F]{6}";
  mkColor = default:
    mkOption {
      type = color;
      inherit default;
    };
  mkDefaults = lib.mapAttrs (_: mkColor);

  p = config.palette;
  r = config.roles;
  dark = config.variant == "dark";
in {
  options = {
    name = mkOption {
      type = types.str;
      description = "Theme name. Set from the file name.";
    };

    label = mkOption {
      type = types.str;
      readOnly = true;
      default = titleCase config.name;
      description = "Display name, e.g. \"Hexagon Light\".";
    };

    variant = mkOption {
      type = types.enum ["dark" "light"];
      default = "dark";
    };

    # Raw colors. Programs should prefer `roles` where one fits.
    palette = lib.genAttrs [
      "bg"
      "bgDark"
      "bgDarker"
      "surface"
      "overlay"
      "fg"
      "fgMuted"
      "accent"
      "accentAlt"
      "accentBright"
      "shadow"
      "red"
      "green"
      "yellow"
      "blue"
      "cyan"
    ] (_: mkOption {type = color;});

    colors = mkOption {
      type = types.attrsOf color;
      readOnly = true;
      default = p // r;
      description = "`palette` and `roles` in one set, which is what targets use.";
    };

    # What a color is used for.
    roles = mkDefaults {
      activeBg = p.overlay;
      activeFg = p.fg;
      accentFg = p.bgDarker;
      border = p.overlay;
      borderStrong = p.accentAlt;
      dangerFg = p.bgDarker;
      disabledFg = p.fgMuted;
      focus = p.accentBright;
      hoverBg = p.surface;
      inputBg = p.bgDarker;
      link = p.accentAlt;
      panelBg = p.bg;
      panelBgAlt = p.bgDark;
      selectionBg = p.accent;
      selectionFg = p.bgDarker;
      successFg = p.bgDarker;
      warningFg = p.bgDarker;
    };

    # Terminal colors, used by kitty and the VSCodium terminal.
    terminal =
      mkDefaults {
        background = p.bg;
        foreground = p.fg;
        cursor = p.accent;
        cursorText = p.bg;
        selectionBg = p.overlay;
        selectionFg = p.fg;
        url = r.link;
        tabActiveBg = r.selectionBg;
        tabActiveFg = p.bg;
        tabInactiveBg = p.surface;
        tabInactiveFg = r.disabledFg;
      }
      // {
        normal = mkDefaults {
          # Every ANSI color is printed as text. On a light background black
          # becomes the text color and bright white can't stay white.
          black =
            if dark
            then p.overlay
            else p.fg;
          red = p.red;
          green = p.green;
          yellow = p.yellow;
          blue = p.blue;
          magenta = p.accent;
          cyan = p.cyan;
          white = p.fg;
        };
        bright = mkDefaults {
          black = r.disabledFg;
          red = p.red;
          green = p.green;
          yellow = p.yellow;
          blue = p.blue;
          magenta = r.focus;
          cyan = p.cyan;
          white =
            if dark
            then "#ffffff"
            else p.fg;
        };
      };

    # Spicetify color.ini keys. The extra shades only exist in Spotify.
    spicetify = mkDefaults {
      text = p.fg;
      subtext = p.fgMuted;
      main = p.bg;
      main-elevated = p.surface;
      highlight = p.surface;
      highlight-elevated = p.overlay;
      sidebar = p.bgDark;
      player = p.bgDarker;
      card = p.surface;
      shadow = p.shadow;
      selected-row = p.accent;
      button = p.accent;
      button-active = p.accentBright;
      button-disabled = p.fgMuted;
      tab-active = p.overlay;
      notification = p.surface;
      notification-error = p.red;
      equalizer = "#000000";
      misc = p.overlay;
      header = p.surface;
      surface0 = p.surface;
      surface1 = p.surface;
      surface2 = p.overlay;
      overlay0 = p.overlay;
      overlay1 = p.fgMuted;
      overlay2 = p.fg;
      accent = p.accent;
      accentalt = p.accentAlt;
      accentbright = p.accentBright;
      red = p.red;
      green = p.green;
      yellow = p.yellow;
      blue = p.blue;
      cyan = p.cyan;
    };

    gnomeAccent = mkOption {
      type = types.enum ["blue" "teal" "green" "yellow" "orange" "red" "pink" "purple" "slate"];
      default = "blue";
      description = "Closest GNOME accent preset, exposed to apps through the settings portal.";
    };

    gtk = {
      name = mkOption {
        type = types.str;
        default =
          if dark
          then "adw-gtk3-dark"
          else "adw-gtk3";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.adw-gtk3;
      };
    };

    # Papirus, with folders recolored to match `gnomeAccent`.
    icons = {
      name = mkOption {
        type = types.str;
        default =
          if dark
          then "Papirus-Dark"
          else "Papirus-Light";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.papirus-icon-theme.override {
          color =
            {
              blue = "blue";
              teal = "teal";
              green = "green";
              yellow = "yellow";
              orange = "orange";
              red = "red";
              pink = "pink";
              purple = "violet";
              slate = "grey";
            }
            .${
              config.gnomeAccent
            };
        };
      };
    };

    cursor = {
      name = mkOption {
        type = types.str;
        default = "Bibata-Modern-Classic";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.bibata-cursors;
      };
      size = mkOption {
        type = types.int;
        default = 24;
      };
    };

    fonts = {
      sans = mkOption {
        type = types.str;
        default = "Noto Sans 11";
      };
      document = mkOption {
        type = types.str;
        default = config.fonts.sans;
      };
      mono = mkOption {
        type = types.str;
        default = "JetBrains Mono 11";
      };
    };

    qt = {
      kvantum = mkOption {
        type = types.str;
        default =
          if dark
          then "KvArcDark"
          else "KvArc";
      };
      lookAndFeel = mkOption {
        type = types.str;
        default =
          if dark
          then "org.kde.breezedark.desktop"
          else "org.kde.breeze.desktop";
      };
      colorScheme = mkOption {
        type = types.str;
        default = lib.replaceStrings [" "] [""] config.label;
        description = "Name of the generated KDE/qtct color scheme.";
      };
    };
  };
}
