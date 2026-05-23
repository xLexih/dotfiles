{lib}: let
  stripHex = hex: lib.removePrefix "#" hex;

  hexToRgb = hex: let
    clean = stripHex hex;
  in {
    r = lib.fromHexString (builtins.substring 0 2 clean);
    g = lib.fromHexString (builtins.substring 2 2 clean);
    b = lib.fromHexString (builtins.substring 4 2 clean);
  };

  rgbCsv = hex: let
    rgb = hexToRgb hex;
  in "${toString rgb.r},${toString rgb.g},${toString rgb.b}";

  argb = hex: "#ff${stripHex hex}";
  argbAlpha = alpha: hex: "#${alpha}${stripHex hex}";

  promptColorFor = theme: let
    accentRgb = hexToRgb theme.ui.accent;
  in "38;2;${toString accentRgb.r};${toString accentRgb.g};${toString accentRgb.b}m";

  fontParts = font: let
    parts = lib.splitString " " font;
    size = lib.last parts;
    family = lib.concatStringsSep " " (lib.init parts);
  in {
    inherit family size;
  };

  qtFont = font: let
    parsed = fontParts font;
  in "${parsed.family},${parsed.size},-1,5,50,0,0,0,0,0";

  gtkPreferDark = theme:
    if theme.gtk.preferDark or true
    then "1"
    else "0";

  qtColorRows = t: {
    active = [
      (argb t.fg)
      (argb t.bg)
      (argb t.surface)
      (argb t.bgDark)
      (argb t.bgDarker)
      (argb t.surface)
      (argb t.fg)
      "#ffffffff"
      (argb t.fg)
      (argb t.bgDarker)
      (argb t.bgDark)
      (argb t.overlay)
      (argb t.accent)
      (argb t.bg)
      (argb t.accentAlt)
      (argb t.fgMuted)
      (argb t.shadow)
      (argb t.fg)
      (argb t.bg)
      (argb t.fg)
      (argbAlpha "80" t.fg)
    ];
    disabled = [
      (argb t.fgMuted)
      (argb t.bg)
      (argb t.surface)
      (argb t.bgDark)
      (argb t.bgDarker)
      (argb t.surface)
      (argb t.fgMuted)
      "#ffffffff"
      (argb t.fgMuted)
      (argb t.bgDarker)
      (argb t.bgDark)
      (argb t.overlay)
      (argb t.accent)
      (argb t.fgMuted)
      (argb t.accentAlt)
      (argb t.fgMuted)
      (argb t.shadow)
      (argb t.fg)
      (argb t.bg)
      (argb t.fgMuted)
      (argbAlpha "60" t.fgMuted)
    ];
    inactive = [
      (argb t.fg)
      (argb t.bg)
      (argb t.surface)
      (argb t.bgDark)
      (argb t.bgDarker)
      (argb t.surface)
      (argb t.fg)
      "#ffffffff"
      (argb t.fg)
      (argb t.bgDarker)
      (argb t.bgDark)
      (argb t.overlay)
      (argb t.accentAlt)
      (argb t.bg)
      (argb t.accentAlt)
      (argb t.fgMuted)
      (argb t.shadow)
      (argb t.fg)
      (argb t.bg)
      (argb t.fg)
      (argbAlpha "70" t.fg)
    ];
  };

  qtColorLine = colors: lib.concatStringsSep ", " colors;

  mkKdeColorGroups = t: ''
    [Colors:Button]
    BackgroundAlternate=${rgbCsv t.bgDark}
    BackgroundNormal=${rgbCsv t.surface}
    DecorationFocus=${rgbCsv t.accent}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.fgMuted}
    ForegroundLink=${rgbCsv t.accentAlt}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:Complementary]
    BackgroundAlternate=${rgbCsv t.bg}
    BackgroundNormal=${rgbCsv t.bgDarker}
    DecorationFocus=${rgbCsv t.accent}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.fgMuted}
    ForegroundLink=${rgbCsv t.accentAlt}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:Selection]
    BackgroundAlternate=${rgbCsv t.accentBright}
    BackgroundNormal=${rgbCsv t.accent}
    DecorationFocus=${rgbCsv t.accent}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.bg}
    ForegroundInactive=${rgbCsv t.bg}
    ForegroundLink=${rgbCsv t.bgDarker}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.bg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.bgDarker}

    [Colors:Tooltip]
    BackgroundAlternate=${rgbCsv t.bg}
    BackgroundNormal=${rgbCsv t.surface}
    DecorationFocus=${rgbCsv t.accent}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.fgMuted}
    ForegroundLink=${rgbCsv t.accentAlt}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:View]
    BackgroundAlternate=${rgbCsv t.bg}
    BackgroundNormal=${rgbCsv t.bgDark}
    DecorationFocus=${rgbCsv t.accent}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.fgMuted}
    ForegroundLink=${rgbCsv t.accentAlt}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:Window]
    BackgroundAlternate=${rgbCsv t.bgDark}
    BackgroundNormal=${rgbCsv t.bg}
    DecorationFocus=${rgbCsv t.accent}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.fgMuted}
    ForegroundLink=${rgbCsv t.accentAlt}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}
  '';

  gtk3CssFor = theme: let
    t = theme.ui;
  in ''
    @define-color theme_bg_color ${t.bg};
    @define-color theme_fg_color ${t.fg};
    @define-color theme_base_color ${t.bgDark};
    @define-color theme_selected_bg_color ${t.accent};
    @define-color theme_selected_fg_color ${t.bg};
    @define-color theme_unfocused_bg_color ${t.bg};
    @define-color theme_unfocused_fg_color ${t.fgMuted};
    @define-color borders ${t.overlay};
    @define-color insensitive_bg_color ${t.surface};
    @define-color insensitive_fg_color ${t.fgMuted};
    @define-color error_color ${t.red};
    @define-color warning_color ${t.yellow};
    @define-color success_color ${t.green};

    window, .background, dialog, messagedialog {
      background-color: ${t.bg};
      color: ${t.fg};
    }

    headerbar, .titlebar {
      background-color: ${t.bgDark};
      background-image: none;
      color: ${t.fg};
      border-bottom: 1px solid ${t.overlay};
      box-shadow: none;
    }

    headerbar *, .titlebar * {
      background-image: none;
    }

    .path-bar, .path-bar button, .linked button,
    toolbar, .toolbar {
      background-color: ${t.bgDark};
      background-image: none;
      color: ${t.fg};
    }

    .sidebar, placessidebar, .navigation-sidebar,
    .sidebar .view, placessidebar .view {
      background-color: ${t.bgDark};
      color: ${t.fg};
    }

    .sidebar row:selected, placessidebar row:selected,
    .navigation-sidebar row:selected {
      background-color: ${t.accent};
      color: ${t.bg};
    }

    .view, treeview.view, iconview, list, listbox {
      background-color: ${t.bgDark};
      color: ${t.fg};
    }

    row:selected, .view:selected, treeview.view:selected,
    list row:selected, listbox row:selected {
      background-color: ${t.accent};
      color: ${t.bg};
    }

    row:hover, list row:hover, listbox row:hover {
      background-color: ${t.surface};
    }

    button {
      background-color: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.overlay};
    }

    button:hover {
      background-color: ${t.overlay};
    }

    button:active, button:checked {
      background-color: ${t.accent};
      color: ${t.bg};
    }

    button.suggested-action {
      background-color: ${t.accent};
      color: ${t.bg};
    }

    entry, spinbutton {
      background-color: ${t.bgDark};
      color: ${t.fg};
      border: 1px solid ${t.overlay};
    }

    entry:focus, spinbutton:focus {
      border-color: ${t.accent};
    }

    menu, .menu, .context-menu, popover, popover.background {
      background-color: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.overlay};
    }

    menu menuitem:hover, popover modelbutton:hover {
      background-color: ${t.overlay};
    }

    separator {
      background-color: ${t.overlay};
    }

    scrollbar slider {
      background-color: ${t.overlay};
    }

    scrollbar slider:hover {
      background-color: ${t.fgMuted};
    }

    check:checked, radio:checked {
      background-color: ${t.accent};
      color: ${t.bg};
    }

    progressbar progress, scale highlight {
      background-color: ${t.accent};
    }

    tooltip, tooltip.background {
      background-color: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.overlay};
    }

    notebook header tab:checked {
      border-bottom-color: ${t.accent};
    }
  '';

  gtk4CssFor = theme: let
    t = theme.ui;
  in ''
    @define-color accent_bg_color ${t.accent};
    @define-color accent_fg_color ${t.bg};
    @define-color accent_color ${t.accent};
    @define-color destructive_bg_color ${t.red};
    @define-color destructive_fg_color ${t.bg};
    @define-color success_bg_color ${t.green};
    @define-color success_fg_color ${t.bg};
    @define-color warning_bg_color ${t.yellow};
    @define-color warning_fg_color ${t.bg};
    @define-color error_bg_color ${t.red};
    @define-color error_fg_color ${t.bg};
    @define-color window_bg_color ${t.bg};
    @define-color window_fg_color ${t.fg};
    @define-color view_bg_color ${t.bgDark};
    @define-color view_fg_color ${t.fg};
    @define-color headerbar_bg_color ${t.bgDark};
    @define-color headerbar_fg_color ${t.fg};
    @define-color headerbar_border_color ${t.overlay};
    @define-color headerbar_backdrop_color ${t.bgDark};
    @define-color card_bg_color ${t.surface};
    @define-color card_fg_color ${t.fg};
    @define-color sidebar_bg_color ${t.bgDark};
    @define-color sidebar_fg_color ${t.fg};
    @define-color sidebar_backdrop_color ${t.bgDark};
    @define-color secondary_sidebar_bg_color ${t.bgDark};
    @define-color secondary_sidebar_fg_color ${t.fg};
    @define-color secondary_sidebar_backdrop_color ${t.bgDark};
    @define-color popover_bg_color ${t.surface};
    @define-color popover_fg_color ${t.fg};
    @define-color dialog_bg_color ${t.surface};
    @define-color dialog_fg_color ${t.fg};
    @define-color shade_color rgba(0, 0, 0, 0.25);
    @define-color scrollbar_outline_color ${t.overlay};

    * {
      --accent-bg-color: ${t.accent};
      --accent-fg-color: ${t.bg};
      --accent-color: ${t.accent};
      --destructive-bg-color: ${t.red};
      --destructive-fg-color: ${t.bg};
      --success-bg-color: ${t.green};
      --success-fg-color: ${t.bg};
      --warning-bg-color: ${t.yellow};
      --warning-fg-color: ${t.bg};
      --error-bg-color: ${t.red};
      --error-fg-color: ${t.bg};
      --window-bg-color: ${t.bg};
      --window-fg-color: ${t.fg};
      --view-bg-color: ${t.bgDark};
      --view-fg-color: ${t.fg};
      --headerbar-bg-color: ${t.bgDark};
      --headerbar-fg-color: ${t.fg};
      --headerbar-border-color: ${t.overlay};
      --headerbar-backdrop-color: ${t.bgDark};
      --card-bg-color: ${t.surface};
      --card-fg-color: ${t.fg};
      --sidebar-bg-color: ${t.bgDark};
      --sidebar-fg-color: ${t.fg};
      --sidebar-backdrop-color: ${t.bgDark};
      --popover-bg-color: ${t.surface};
      --popover-fg-color: ${t.fg};
      --dialog-bg-color: ${t.surface};
      --dialog-fg-color: ${t.fg};
    }

    window, window.background,
    .background {
      background-color: ${t.bg};
      color: ${t.fg};
    }

    window:backdrop, window.background:backdrop {
      background-color: ${t.bg};
      color: ${t.fg};
    }

    headerbar, .titlebar, .top-bar,
    headerbar.default-decoration,
    window headerbar, window .titlebar,
    .toolbar-view > .top-bar,
    .toolbar-view > .bottom-bar {
      background-color: ${t.bgDark};
      background-image: none;
      color: ${t.fg};
      border-bottom: 1px solid ${t.overlay};
      box-shadow: none;
    }

    headerbar:backdrop, .titlebar:backdrop,
    window headerbar:backdrop, window .titlebar:backdrop,
    .toolbar-view > .top-bar:backdrop,
    .toolbar-view > .bottom-bar:backdrop {
      background-color: ${t.bgDark};
      background-image: none;
      color: ${t.fg};
    }

    headerbar button, .titlebar button,
    headerbar stackswitcher button,
    headerbar splitbutton button {
      background: ${t.surface};
      color: ${t.fg};
    }

    headerbar button:hover, .titlebar button:hover {
      background: ${t.overlay};
      color: ${t.fg};
    }

    headerbar button:active, headerbar button:checked {
      background: ${t.accent};
      color: ${t.bg};
    }

    headerbar entry, .titlebar entry,
    headerbar search > entry {
      background: ${t.bgDarker};
      color: ${t.fg};
    }

    .sidebar-pane, .navigation-sidebar,
    .sidebar-pane list, .sidebar-pane .view {
      background-color: ${t.bgDark};
      color: ${t.fg};
    }

    .sidebar-pane:backdrop, .navigation-sidebar:backdrop,
    window:backdrop .sidebar-pane,
    window:backdrop .navigation-sidebar {
      background-color: ${t.bgDark};
      color: ${t.fg};
    }

    .navigation-sidebar > row:selected {
      background-color: ${t.accent};
      color: ${t.bg};
    }

    .view, list, listview, columnview, gridview {
      background-color: ${t.bgDark};
      color: ${t.fg};
    }

    list > row:selected, listview > row:selected,
    columnview > row:selected, gridview > child:selected {
      background-color: ${t.accent};
      color: ${t.bg};
    }

    list > row:hover, listview > row:hover,
    columnview > row:hover {
      background-color: ${t.surface};
      color: ${t.fg};
    }

    button {
      background: ${t.surface};
      color: ${t.fg};
    }

    button:hover {
      background: ${t.overlay};
      color: ${t.fg};
    }

    button:active, button:checked,
    button.suggested-action {
      background: ${t.accent};
      color: ${t.bg};
    }

    button.destructive-action {
      background: ${t.red};
      color: ${t.bg};
    }

    button:disabled {
      color: ${t.fgMuted};
    }

    .suffixes > button {
      background: ${t.bgDark};
      color: ${t.fg};
      border: 1px solid ${t.overlay};
      transition: background 150ms ease, color 150ms ease, border-color 150ms ease;
    }

    .suffixes > button:hover {
      background: ${t.surface};
      color: ${t.fg};
      border-color: ${t.accentAlt};
    }

    .suffixes > button:active {
      background: ${t.accent};
      color: ${t.bg};
      border-color: ${t.accent};
      transition: background 80ms ease;
    }

    entry, spinbutton, searchbar > revealer > box {
      background: ${t.bgDark};
      color: ${t.fg};
    }

    entry:focus-within, spinbutton:focus-within {
      outline-color: ${t.accent};
    }

    popover > contents, .context-menu {
      background: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.overlay};
    }

    popover modelbutton:hover, popover row:hover,
    .context-menu .activatable:hover {
      background: ${t.overlay};
      color: ${t.fg};
    }

    .card, .boxed-list {
      background: ${t.surface};
      color: ${t.fg};
    }

    .card:backdrop, .boxed-list:backdrop {
      background: ${t.surface};
      color: ${t.fg};
    }

    separator {
      background: ${t.overlay};
    }

    scrollbar > range > trough > slider {
      background: ${t.overlay};
    }

    scrollbar > range > trough > slider:hover {
      background: ${t.fgMuted};
    }

    check:checked, radio:checked {
      background: ${t.accent};
      color: ${t.bg};
    }

    scale > trough > highlight {
      background: ${t.accent};
    }

    progressbar > trough > progress {
      background: ${t.accent};
    }

    switch:checked {
      background: ${t.accent};
    }

    tabbar tab, notebook > header > tabs > tab {
      background: ${t.bgDark};
      color: ${t.fgMuted};
    }

    tabbar tab:checked, notebook > header > tabs > tab:checked {
      background: ${t.bg};
      color: ${t.fg};
    }

    .toolbar, searchbar, .search-bar {
      background: ${t.bgDark};
      color: ${t.fg};
    }

    tooltip {
      background: ${t.surface};
      color: ${t.fg};
    }

    .property-row, .preferences group row {
      background: ${t.surface};
      color: ${t.fg};
    }
  '';

  mkGtkTheme = {theme}: {
    dconfSettings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = theme.gtk.name;
        icon-theme = theme.icon.name;
        cursor-theme = theme.cursor.name;
        cursor-size = lib.gvariant.mkInt32 theme.cursor.size;
        font-name = theme.font.sans;
        document-font-name = theme.font.document;
        monospace-font-name = theme.font.mono;
        color-scheme = "prefer-dark";
        accent-color = theme.gnomeAccent;
        font-antialiasing = "rgba";
        font-hinting = "slight";
        font-rgba-order = "rgb";
      };
      "org/freedesktop/appearance" = {
        color-scheme = lib.gvariant.mkUint32 1;
        accent-color = theme.gnomeAccent;
      };
    };

    gtk2Rc = ''
      gtk-theme-name="${theme.gtk.name}"
      gtk-icon-theme-name="${theme.icon.name}"
      gtk-cursor-theme-name="${theme.cursor.name}"
      gtk-cursor-theme-size=${toString theme.cursor.size}
      gtk-font-name="${theme.font.sans}"
      gtk-application-prefer-dark-theme=${gtkPreferDark theme}
    '';

    gtkSettings = ''
      [Settings]
      gtk-theme-name=${theme.gtk.name}
      gtk-icon-theme-name=${theme.icon.name}
      gtk-cursor-theme-name=${theme.cursor.name}
      gtk-cursor-theme-size=${toString theme.cursor.size}
      gtk-font-name=${theme.font.sans}
      gtk-application-prefer-dark-theme=${gtkPreferDark theme}
    '';

    gtk3Css = gtk3CssFor theme;
    gtk4Css = gtk4CssFor theme;
  };

  mkQtTheme = {theme}: let
    t = theme.ui;
    rows = qtColorRows t;
    colorSchemeName = theme.qt.colorScheme or theme.name;
    colorSchemeFileName = "${colorSchemeName}.colors";
    qtctColorSchemeFileName = "${colorSchemeName}.conf";
    qtctStyle = theme.qt.qtctStyle or "kvantum-dark";
    platformTheme = theme.qt.platformTheme or "qt5ct";
    style = theme.qt.style or "kvantum";
    kvantumTheme = theme.qt.kvantum or "KvArcDark";
    kdeLookAndFeel = theme.qt.kdeLookAndFeel or "org.kde.breezedark.desktop";
    generalFont = qtFont theme.font.sans;
    fixedFont = qtFont theme.font.mono;
    qtctConfig = app: ''
      [Appearance]
      color_scheme_path=/etc/xdg/${app}/colors/${qtctColorSchemeFileName}
      custom_palette=true
      icon_theme=${theme.icon.name}
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
  in {
    inherit
      colorSchemeFileName
      colorSchemeName
      fixedFont
      generalFont
      kdeLookAndFeel
      kvantumTheme
      platformTheme
      qtctColorSchemeFileName
      qtctStyle
      style
      ;

    kvantumConfig = ''
      [General]
      theme=${kvantumTheme}
    '';

    qtctColorScheme = ''
      [ColorScheme]
      active_colors=${qtColorLine rows.active}
      disabled_colors=${qtColorLine rows.disabled}
      inactive_colors=${qtColorLine rows.inactive}
    '';

    qt5ctConfig = qtctConfig "qt5ct";
    qt6ctConfig = qtctConfig "qt6ct";

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
      ColorScheme=${colorSchemeName}
      Name=${colorSchemeName}
      shadeSortColumn=true

      ${mkKdeColorGroups t}
    '';

    kdeGlobals = ''
      [General]
      ColorScheme=${colorSchemeName}
      Name=${colorSchemeName}
      fixed=${fixedFont}
      font=${generalFont}
      menuFont=${generalFont}
      smallestReadableFont=${generalFont}
      toolBarFont=${generalFont}

      [Icons]
      Theme=${theme.icon.name}

      [KDE]
      LookAndFeelPackage=${kdeLookAndFeel}
      SingleClick=false
      widgetStyle=${qtctStyle}

      [UiSettings]
      ColorScheme=${colorSchemeName}

      [WM]
      activeBackground=${rgbCsv t.bg}
      activeBlend=${rgbCsv t.bg}
      activeForeground=${rgbCsv t.fg}
      inactiveBackground=${rgbCsv t.bgDark}
      inactiveBlend=${rgbCsv t.bgDark}
      inactiveForeground=${rgbCsv t.fgMuted}

      ${mkKdeColorGroups t}
    '';
  };

  mkFirefoxTheme = {theme}: let
    t = theme.ui;
    firefoxAccent = "${t.accent}ee";
    firefoxDarkBg = "color-mix(in oklab, ${t.bg}, black 20%)";
  in {
    profilesIni = ''
      [Profile0]
      Name=default
      IsRelative=1
      Path=default
      Default=1

      [General]
      StartWithLastProfile=1
      Version=2
    '';

    userJs = ''
      user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
      user_pref("svg.context-properties.content.enabled", true);
      user_pref("ui.highlight", "${t.accent}");
      user_pref("ui.highlighttext", "${t.bg}");
    '';

    userContent = ''
      @-moz-document url-prefix("about:"), url-prefix("chrome://browser/content/") {
        :root {
          --in-content-page-background: ${t.bg} !important;
          --in-content-page-color: ${t.fg} !important;
          --in-content-primary-button-background: ${t.accent} !important;
          --in-content-primary-button-text-color: ${t.bg} !important;
          --in-content-accent-color: ${t.accent} !important;
          --in-content-box-background: ${t.bgDark} !important;
          --in-content-box-border-color: ${t.overlay} !important;
          --in-content-border-color: ${t.overlay} !important;
          --in-content-link-color: ${t.accentAlt} !important;
          --in-content-table-background: ${t.bgDark} !important;
          --in-content-item-hover: ${t.surface} !important;
          --in-content-item-selected: ${t.overlay} !important;
          --newtab-background-color: ${t.bg} !important;
          --newtab-background-color-secondary: ${t.bgDark} !important;
          --newtab-background-card: ${t.surface} !important;
          --newtab-text-primary-color: ${t.fg} !important;
          --newtab-primary-action-background: ${t.accent} !important;
        }
      }

      #root.root {
        --color-accent-primary: ${firefoxAccent} !important;
        --frame-bg: ${t.bg} !important;
        --frame-fg: var(--color-accent-primary) !important;
        --toolbar-fg: var(--frame-fg) !important;
        --border: ${t.bg} !important;
        --notification-bg: ${t.bg} !important;
        --ctx-menu-bg: ${t.bg} !important;
        --ctx-menu-fg: var(--color-accent-primary);
        --ctx-menu-separator: ${t.overlay} !important;
        --popup-bg: ${t.bg} !important;
        --tabs-normal-fg: color-mix(in oklab, ${firefoxAccent}, transparent 35%) !important;
        --tabs-activated-fg: var(--color-accent-primary) !important;
        --tabs-activated-bg: color-mix(in oklab, ${firefoxAccent}, transparent 75%) !important;
        --toolbar-bg: ${t.bg} !important;
      }
    '';

    userChrome = ''
      :root {
        --chrome-selection-color: ${t.bg} !important;
        --chrome-selection-background-color: ${t.accent} !important;
        --toolbar-bgcolor: ${t.bg} !important;
        --lwt-accent-color: ${t.bg} !important;
        --lwt-text-color: ${t.fg} !important;
        --lwt-toolbar-field-background-color: ${firefoxDarkBg} !important;
        --lwt-toolbar-field-color: ${firefoxAccent} !important;
        --color-accent-primary: ${firefoxAccent} !important;
        --toolbar-color: var(--color-accent-primary) !important;
        --toolbarbutton-icon-fill: var(--color-accent-primary) !important;
        --toolbarbutton-icon-fill-attention: var(--color-accent-primary) !important;
        --toolbar-field-background-color: ${firefoxDarkBg} !important;
        --toolbar-field-focus-background-color: ${firefoxDarkBg} !important;
        --toolbar-field-color: var(--color-accent-primary) !important;
        --toolbar-field-focus-color: var(--color-accent-primary) !important;
        --urlbar-box-bgcolor: ${firefoxDarkBg} !important;
        --urlbarView-highlight-background: color-mix(in oklab, var(--color-accent-primary), transparent 50%) !important;
        --urlbarView-action-color: var(--color-accent-primary) !important;
        --chrome-content-separator-color: var(--color-accent-primary) !important;
        --arrowpanel-border-color: var(--color-accent-primary) !important;
        --toolbarbutton-special-border-radius: 0px 0px 15px 15px / 15px !important;

        --s-frame-bg: ${t.bg} !important;
        --s-border: ${t.bg} !important;
        --s-notification-bg: ${t.bg} !important;
        --s-ctx-menu-bg: ${t.bg} !important;
        --s-ctx-menu-separator: ${t.bg} !important;
        --s-popup-bg: ${t.bg} !important;
        --s-toolbar-bg: ${t.bg} !important;
        --s-tabs-activated-bg: color-mix(in oklab, var(--color-accent-primary), transparent 75%) !important;
      }

      .urlbar-icon,
      .toolbarbutton-icon,
      .urlbar-engine-one-off-item image {
        fill: var(--color-accent-primary) !important;
        -moz-context-properties: fill, fill-opacity !important;
      }

      .urlbar-input {
        color: var(--color-accent-primary) !important;
      }

      .urlbarView-row:is([selected], [row-selectable]:hover) {
        background-color: color-mix(in oklab, ${t.accent}, transparent 50%) !important;
      }

      .urlbarView-row:is([selected], [row-selectable]:hover) :is(.urlbarView-title, .urlbarView-url, .urlbarView-action) {
        color: ${t.fg} !important;
      }

      #urlbar:is([focused], [open])[breakout-extend] > #urlbar-background {
        border-radius: var(--toolbarbutton-special-border-radius) !important;
      }

      #statuspanel-label {
        background-color: var(--color-accent-primary) !important;
        color: ${t.bg} !important;
      }

      #TabsToolbar,
      #sidebar-header,
      #sidebar-splitter-disabled {
        display: none !important;
      }

      menupopup,
      panel {
        --panel-background: ${t.bg} !important;
        --panel-color: ${t.fg} !important;
        --panel-border-color: ${t.overlay} !important;
      }

      menupopup {
        background-color: ${t.bg} !important;
        color: ${t.fg} !important;
        border: none !important;
        box-shadow: 0 4px 12px ${t.shadow} !important;
      }

      menuitem,
      menu {
        color: ${t.fg} !important;
      }

      :is(menuitem, menu):is(:hover, [_moz-menuactive="true"]) {
        background-color: ${t.overlay} !important;
        color: ${t.fg} !important;
      }

      menuseparator {
        border-color: ${t.overlay} !important;
      }
    '';
  };
in {
  inherit
    hexToRgb
    mkFirefoxTheme
    mkGtkTheme
    mkQtTheme
    promptColorFor
    rgbCsv
    stripHex
    ;
}
