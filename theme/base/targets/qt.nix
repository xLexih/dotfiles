# Qt through qt5ct/qt6ct with Kvantum, plus KDE color schemes for KDE apps.
# Qt reads these when an application starts.
{
  lib,
  pkgs,
  ...
}: let
  inherit (import ../lib.nix {inherit lib;}) argb argbAlpha qtFont rgbCsv;

  render = theme: let
    t = theme.palette // theme.roles;
    scheme = theme.qt.colorScheme;
    dark = theme.variant == "dark";

    qtctStyle =
      if dark
      then "kvantum-dark"
      else "kvantum";
    generalFont = qtFont theme.fonts.sans;
    fixedFont = qtFont theme.fonts.mono;

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
