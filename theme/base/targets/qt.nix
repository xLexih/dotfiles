# Qt through qt5ct/qt6ct with Kvantum, plus KDE color schemes for KDE apps.
# Qt reads these when an application starts.
{
  lib,
  pkgs,
  ...
}: let
  inherit (import ../lib.nix {inherit lib;}) argb argbAlpha qtFont rgbCsv;
  inherit (lib) replaceStrings;

  # Kvantum themes hardcode their colors in a kvconfig and an SVG. The stock
  # KvArcDark is otherwise the right geometry, so copy it per theme and remap
  # its Arc grays/blues onto the palette. Longest-first, so #ffffffc8 is
  # replaced before #fff and never one of its own suffixes twice.
  kvantumMap = theme: let
    t = theme.colors;
    m = {
      # window / button grays
      "#22252e" = t.bgDark;
      "#3c404e" = t.surface;
      "#343844" = t.bgDark;
      "#444a58" = t.surface;
      "#2d303b" = t.bgDark;
      "#383c4a" = t.bg;
      "#414654" = t.surface;
      "#3c434f" = t.surface;
      "#363c48" = t.surface;
      "#2f343f" = t.bgDark;
      "#2d323d" = t.bgDark;
      "#2b2e39" = t.bgDark;
      "#323542" = t.bgDark;
      "#31353f" = t.bgDark;
      "#22242e" = t.bgDarker;
      "#222224" = t.bgDarker;
      "#262933" = t.bgDarker;
      "#404552" = t.surface;
      "#474d5d" = t.activeBg;
      "#505666" = t.activeBg;
      "#4d5367" = t.activeBg;
      "#5a616e" = t.activeBg;
      "#474d5b" = t.activeBg;
      "#444448" = t.activeBg;
      "#767b87" = t.overlay;
      "#5f677f" = t.overlay;
      "#1e1e1e" = t.bgDarker;
      "#141414" = t.bgDarker;
      "#111217" = t.bgDarker;
      "#191919" = t.shadow;
      "#313131" = t.shadow;
      "#505050" = t.border;
      "#5a5a5a" = t.border;
      "#666" = t.border;
      "#787878" = t.disabledFg;
      "#7b7b7b" = t.disabledFg;
      "#969696" = t.fgMuted;
      "#92959d" = t.fgMuted;
      "#a0a0a0" = t.fgMuted;
      "#acb1bc" = t.fgMuted;
      "#b4b4b4" = t.fgMuted;
      "#c3c3c3" = t.fgMuted;
      "#d2d2d2" = t.fg;
      "#d7d7d7" = t.fg;
      # accents (stock Arc blue + violet)
      "#5294e2" = t.accent;
      "#4693e6" = t.accent;
      "#5796e8" = t.accent;
      "#58acff" = t.accentBright;
      "#3176bf" = t.accentAlt;
      "#0582ff" = t.link;
      "#39f" = t.link;
      "#009DFF" = t.link;
      "#9E4FFF" = t.accentAlt;
      "#b74aff" = t.accentAlt;
      "#f04a50" = t.red;
      # whites -> theme text
      "#ffffffc8" = t.fg;
      "#ffffffb4" = t.fg;
      "#ffffffd2" = t.fg;
      "#ffffff96" = t.fgMuted;
      "#ffffff78" = t.fgMuted;
      "#ffffff73" = t.disabledFg;
      "#ffffff" = t.fg;
      "#fff" = t.fg;
      "#eefcff" = t.fg;
      "#000000b4" = t.shadow;
    };
    # Longest first: "#ffffffc8" before "#ffffff" before "#fff".
    pairs = lib.sort (a: b:
      (lib.stringLength (lib.head (lib.attrNames a)))
      > (lib.stringLength (lib.head (lib.attrNames b))))
    (lib.mapAttrsToList lib.nameValuePair m);
  in
    text: lib.foldl' (acc: kv: replaceStrings [kv.name] [kv.value] acc) text pairs;

  render = theme: let
    t = theme.colors;
    scheme = theme.qt.colorScheme;
    dark = theme.variant == "dark";

    qtctStyle =
      if dark
      then "kvantum-dark"
      else "kvantum";
    generalFont = qtFont theme.fonts.sans;
    fixedFont = qtFont theme.fonts.mono;

    # Recolored copy of the stock Kvantum theme: same geometry, palette
    # colors. kvantum.kvconfig below points at it by name.
    kvantumTheme = let
      # The plugin nixpkgs' config/qt.nix installs for `style = "kvantum"`;
      # Qt5 and Qt6 copies ship identical stock themes.
      stock = pkgs.kdePackages.qtstyleplugin-kvantum;
      stockName = theme.qt.kvantum;
      stockDir = "${stock}/share/Kvantum/${stockName}";
      kvconfig = builtins.readFile "${stockDir}/${stockName}.kvconfig";
      svg = builtins.readFile "${stockDir}/${stockName}.svg";
    in {
      "${stockName}.kvconfig" = kvantumMap theme kvconfig;
      "${stockName}.svg" = kvantumMap theme svg;
    };
    kvantumDir = ".config/Kvantum/${theme.qt.kvantum}";

    # QPalette roles in order: WindowText, Button, Light, Midlight, Dark, Mid,
    # Text, BrightText, ButtonText, Base, Window, Shadow, Highlight,
    # HighlightedText, Link, LinkVisited, AlternateBase, NoRole, ToolTipBase,
    # ToolTipText, PlaceholderText.
    paletteRow = {
      text,
      highlight,
      highlightText,
      placeholderText,
    }:
      lib.concatStringsSep ", " [
        (argb text)
        (argb t.bg)
        (argb t.surface)
        (argb t.bgDark)
        (argb t.bgDarker)
        (argb t.surface)
        (argb text)
        "#ffffffff"
        (argb text)
        (argb t.bgDarker)
        (argb t.bgDark)
        (argb t.border)
        (argb highlight)
        (argb highlightText)
        (argb t.link)
        (argb t.disabledFg)
        (argb t.shadow)
        (argb t.fg)
        (argb t.bg)
        (argb text)
        placeholderText
      ];

    qtctColors = ''
      [ColorScheme]
      active_colors=${paletteRow {
        text = t.fg;
        highlight = t.selectionBg;
        highlightText = t.selectionFg;
        placeholderText = argbAlpha "80" t.disabledFg;
      }}
      disabled_colors=${paletteRow {
        text = t.fgMuted;
        highlight = t.activeBg;
        highlightText = t.disabledFg;
        placeholderText = argbAlpha "60" t.fgMuted;
      }}
      inactive_colors=${paletteRow {
        text = t.fg;
        highlight = t.activeBg;
        highlightText = t.selectionFg;
        placeholderText = argbAlpha "70" t.fg;
      }}
    '';

    qtctConfig = ''
      [Appearance]
      color_scheme_path=@HOME@/.config/qt6ct/colors/theme.conf
      custom_palette=true
      icon_theme=${theme.icons.name}
      standard_dialogs=xdgdesktopportal
      style=${qtctStyle}

      [Fonts]
      fixed="${fixedFont}"
      general="${generalFont}"

      [Interface]
      activate_item_on_single_click=0
      buttonbox_layout=0
      cursor_flash_time=1000
      dialog_buttons_have_icons=1
      double_click_interval=400
      gui_effects=@Invalid()
      keyboard_scheme=2
      menus_have_icons=true
      show_shortcuts_in_context_menus=true
      stylesheets=@Invalid()
      toolbutton_style=4
      underline_shortcut=1
      wheel_scroll_lines=3
    '';

    colorGroup = name: {
      normal,
      alternate,
      selection ? false,
    }: let
      fg = color:
        if selection
        then t.selectionFg
        else color;
    in ''
      [Colors:${name}]
      BackgroundAlternate=${rgbCsv alternate}
      BackgroundNormal=${rgbCsv normal}
      DecorationFocus=${rgbCsv t.focus}
      DecorationHover=${rgbCsv t.accentBright}
      ForegroundActive=${rgbCsv (fg t.accent)}
      ForegroundInactive=${rgbCsv (fg t.disabledFg)}
      ForegroundLink=${rgbCsv (fg t.link)}
      ForegroundNegative=${rgbCsv (fg t.red)}
      ForegroundNeutral=${rgbCsv (fg t.yellow)}
      ForegroundNormal=${rgbCsv (fg t.fg)}
      ForegroundPositive=${rgbCsv (fg t.green)}
      ForegroundVisited=${rgbCsv (fg t.accentBright)}
    '';

    colorGroups = lib.concatStringsSep "\n" [
      (colorGroup "Button" {
        normal = t.surface;
        alternate = t.bgDark;
      })
      (colorGroup "Complementary" {
        normal = t.bgDarker;
        alternate = t.bg;
      })
      (colorGroup "Selection" {
        normal = t.selectionBg;
        alternate = t.focus;
        selection = true;
      })
      (colorGroup "Tooltip" {
        normal = t.surface;
        alternate = t.bg;
      })
      (colorGroup "View" {
        normal = t.bgDark;
        alternate = t.bg;
      })
      (colorGroup "Window" {
        normal = t.bg;
        alternate = t.bgDark;
      })
    ];

    kdeColorScheme = ''
      [ColorEffects:Disabled]
      ChangeSelectionColor=
      Color=${rgbCsv t.fgMuted}
      ColorAmount=0
      ColorEffect=0
      ContrastAmount=0.65
      ContrastEffect=1
      IntensityAmount=0.1
      IntensityEffect=2

      [ColorEffects:Inactive]
      ChangeSelectionColor=true
      Color=${rgbCsv t.fgMuted}
      ColorAmount=0.025
      ColorEffect=2
      ContrastAmount=0.1
      ContrastEffect=2
      IntensityAmount=0
      IntensityEffect=0

      [General]
      ColorScheme=${scheme}
      Name=${scheme}
      shadeSortColumn=true

      ${colorGroups}
    '';

    kdeGlobals = ''
      [General]
      ColorScheme=${scheme}
      Name=${scheme}
      fixed=${fixedFont}
      font=${generalFont}
      menuFont=${generalFont}
      smallestReadableFont=${generalFont}
      toolBarFont=${generalFont}

      [Icons]
      Theme=${theme.icons.name}

      [KDE]
      LookAndFeelPackage=${theme.qt.lookAndFeel}
      SingleClick=false
      widgetStyle=${qtctStyle}

      [UiSettings]
      ColorScheme=${scheme}

      [WM]
      activeBackground=${rgbCsv t.bg}
      activeBlend=${rgbCsv t.bg}
      activeForeground=${rgbCsv t.fg}
      inactiveBackground=${rgbCsv t.bgDark}
      inactiveBlend=${rgbCsv t.bgDark}
      inactiveForeground=${rgbCsv t.fgMuted}

      ${colorGroups}
    '';
  in {
    ".config/Kvantum/kvantum.kvconfig" = ''
      [General]
      theme=${theme.qt.kvantum}
    '';
    "${kvantumDir}/${theme.qt.kvantum}.kvconfig" = kvantumTheme."${theme.qt.kvantum}.kvconfig";
    "${kvantumDir}/${theme.qt.kvantum}.svg" = kvantumTheme."${theme.qt.kvantum}.svg";
    ".config/qt5ct/qt5ct.conf" = qtctConfig;
    ".config/qt6ct/colors/theme.conf" = qtctColors;
    ".config/qt6ct/qt6ct.conf" = qtctConfig;
    ".config/kdeglobals" = kdeGlobals;
    ".config/kdedefaults/kdeglobals" = kdeGlobals;
    ".local/share/color-schemes/${scheme}.colors" = kdeColorScheme;
  };
in {
  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };

  modules.theme.render.qt = render;

  environment.systemPackages = with pkgs.kdePackages; [
    breeze
    breeze-icons
    kde-cli-tools
  ];
}
