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

  mkThemeRoles = theme: let
    t = theme.ui;
  in
    {
      activeBg = t.overlay;
      activeFg = t.fg;
      accentFg = t.bgDarker;
      border = t.overlay;
      borderStrong = t.accentAlt;
      dangerFg = t.bgDarker;
      disabledFg = t.fgMuted;
      focus = t.accentBright;
      hoverBg = t.surface;
      inputBg = t.bgDarker;
      link = t.accentAlt;
      panelBg = t.bg;
      panelBgAlt = t.bgDark;
      selectionBg = t.accent;
      selectionFg = t.bgDarker;
      successFg = t.bgDarker;
      warningFg = t.bgDarker;
    }
    // (theme.roles or {});

  mkThemePalette = theme:
    theme.ui // mkThemeRoles theme;
  unknownAppSlots = prefix: template: overrides:
    lib.flatten (lib.mapAttrsToList (name: value: let
      path = prefix ++ [name];
    in
      if !(builtins.hasAttr name template)
      then [(lib.concatStringsSep "." path)]
      else if lib.isAttrs value && lib.isAttrs template.${name}
      then unknownAppSlots path template.${name} value
      else if lib.isAttrs value != lib.isAttrs template.${name}
      then [(lib.concatStringsSep "." path)]
      else [])
    overrides);

  resolveAppSlots = template: overrides: let
    unknown = unknownAppSlots [] template overrides;
  in
    if unknown != []
    then throw "Unknown app theme slots: ${lib.concatStringsSep ", " unknown}"
    else lib.recursiveUpdate template overrides;

  mkKittyTheme = app: ''
    background ${app.background}
    foreground ${app.foreground}
    cursor ${app.cursor}
    cursor_text_color ${app.cursorText}
    selection_background ${app.selection}
    selection_foreground ${app.selectionFg}
    url_color ${app.url}

    active_tab_background ${app.tab.activeBg}
    active_tab_foreground ${app.tab.activeFg}
    inactive_tab_background ${app.tab.inactiveBg}
    inactive_tab_foreground ${app.tab.inactiveFg}

    color0 ${app.normal.black}
    color1 ${app.normal.red}
    color2 ${app.normal.green}
    color3 ${app.normal.yellow}
    color4 ${app.normal.blue}
    color5 ${app.normal.magenta}
    color6 ${app.normal.cyan}
    color7 ${app.normal.white}
    color8 ${app.bright.black}
    color9 ${app.bright.red}
    color10 ${app.bright.green}
    color11 ${app.bright.yellow}
    color12 ${app.bright.blue}
    color13 ${app.bright.magenta}
    color14 ${app.bright.cyan}
    color15 ${app.bright.white}
  '';

  uiTokenNames = {
    accent = "ACCENT";
    accentAlt = "ACCENT_ALT";
    accentBright = "ACCENT_BRIGHT";
    bg = "BG";
    bgDark = "BG_DARK";
    bgDarker = "BG_DARKER";
    blue = "BLUE";
    cyan = "CYAN";
    fg = "FG";
    fgMuted = "FG_MUTED";
    green = "GREEN";
    overlay = "OVERLAY";
    red = "RED";
    shadow = "SHADOW";
    surface = "SURFACE";
    yellow = "YELLOW";
  };

  roleTokenNames = {
    activeBg = "ACTIVE_BG";
    activeFg = "ACTIVE_FG";
    accentFg = "ACCENT_FG";
    border = "BORDER";
    borderStrong = "BORDER_STRONG";
    dangerFg = "DANGER_FG";
    disabledFg = "DISABLED_FG";
    focus = "FOCUS";
    hoverBg = "HOVER_BG";
    inputBg = "INPUT_BG";
    link = "LINK";
    panelBg = "PANEL_BG";
    panelBgAlt = "PANEL_BG_ALT";
    selectionBg = "SELECTION_BG";
    selectionFg = "SELECTION_FG";
    successFg = "SUCCESS_FG";
    warningFg = "WARNING_FG";
  };

  lowerTokenName = token: lib.toLower token;

  mkPrefixedTokens = prefix: tokenNames: attrs:
    lib.mapAttrs' (
      name: token:
        lib.nameValuePair "${prefix}${token}" attrs.${name}
    )
    (lib.filterAttrs (name: _: builtins.hasAttr name attrs) tokenNames);

  mkDotfileSubstitutions = prefix: tokenNames: attrs:
    lib.mapAttrs' (
      name: token: let
        lower = lowerTokenName token;
        value = attrs.${name};
      in
        lib.nameValuePair (prefix + lower + "}}") value
    )
    (lib.filterAttrs (name: _: builtins.hasAttr name attrs) tokenNames);

  mkThemeTokens = {
    qt,
    theme,
  }: let
    roles = mkThemeRoles theme;

    uiSessionVariables = mkPrefixedTokens "THEME_" uiTokenNames theme.ui;
    roleSessionVariables = mkPrefixedTokens "THEME_ROLE_" roleTokenNames roles;

    uiDotfileSubstitutions =
      (mkDotfileSubstitutions "{{ui_" uiTokenNames theme.ui)
      // lib.mapAttrs' (
        name: token: let
          lower = lowerTokenName token;
          value = theme.ui.${name};
        in
          lib.nameValuePair "{{ui_${lower}_hex}}" (stripHex value)
      )
      (lib.filterAttrs (name: _: builtins.hasAttr name theme.ui) uiTokenNames);
    roleDotfileSubstitutions = mkDotfileSubstitutions "{{role_" roleTokenNames roles;
  in {
    sessionVariables =
      {
        GTK_THEME = theme.gtk.name;
        THEME_NAME = theme.name;
        THEME_GTK = theme.gtk.name;
        THEME_ICON = theme.icon.name;
        THEME_CURSOR = theme.cursor.name;
        THEME_CURSOR_SIZE = toString theme.cursor.size;
        PROMPT_COLOR = promptColorFor theme;
      }
      // uiSessionVariables
      // roleSessionVariables;

    dotfileSubstitutions =
      {
        "{{gtk_theme}}" = theme.gtk.name;
        "{{icon_theme}}" = theme.icon.name;
        "{{cursor_theme}}" = theme.cursor.name;
        "{{cursor_theme_name}}" = theme.cursor.name;
        "{{cursor_size}}" = toString theme.cursor.size;
        "{{font_sans}}" = theme.font.sans;
        "{{font_document}}" = theme.font.document;
        "{{font_mono}}" = theme.font.mono;
        "{{qt_platform_theme}}" = qt.platformTheme;
        "{{qt_style}}" = qt.style;
        "{{quickshell_primary}}" = theme.ui.surface;
        "{{quickshell_secondary}}" = theme.ui.accent;
        "{{quickshell_secondary_bright}}" = theme.ui.accentBright;
      }
      // uiDotfileSubstitutions
      // roleDotfileSubstitutions;
  };

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
      (argb t.border)
      (argb t.selectionBg)
      (argb t.selectionFg)
      (argb t.link)
      (argb t.disabledFg)
      (argb t.shadow)
      (argb t.fg)
      (argb t.bg)
      (argb t.fg)
      (argbAlpha "80" t.disabledFg)
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
      (argb t.border)
      (argb t.activeBg)
      (argb t.disabledFg)
      (argb t.link)
      (argb t.disabledFg)
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
      (argb t.border)
      (argb t.activeBg)
      (argb t.selectionFg)
      (argb t.link)
      (argb t.disabledFg)
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
    DecorationFocus=${rgbCsv t.focus}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.disabledFg}
    ForegroundLink=${rgbCsv t.link}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:Complementary]
    BackgroundAlternate=${rgbCsv t.bg}
    BackgroundNormal=${rgbCsv t.bgDarker}
    DecorationFocus=${rgbCsv t.focus}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.disabledFg}
    ForegroundLink=${rgbCsv t.link}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:Selection]
    BackgroundAlternate=${rgbCsv t.focus}
    BackgroundNormal=${rgbCsv t.selectionBg}
    DecorationFocus=${rgbCsv t.focus}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.selectionFg}
    ForegroundInactive=${rgbCsv t.selectionFg}
    ForegroundLink=${rgbCsv t.selectionFg}
    ForegroundNegative=${rgbCsv t.selectionFg}
    ForegroundNeutral=${rgbCsv t.selectionFg}
    ForegroundNormal=${rgbCsv t.selectionFg}
    ForegroundPositive=${rgbCsv t.selectionFg}
    ForegroundVisited=${rgbCsv t.selectionFg}

    [Colors:Tooltip]
    BackgroundAlternate=${rgbCsv t.bg}
    BackgroundNormal=${rgbCsv t.surface}
    DecorationFocus=${rgbCsv t.focus}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.disabledFg}
    ForegroundLink=${rgbCsv t.link}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:View]
    BackgroundAlternate=${rgbCsv t.bg}
    BackgroundNormal=${rgbCsv t.bgDark}
    DecorationFocus=${rgbCsv t.focus}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.disabledFg}
    ForegroundLink=${rgbCsv t.link}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}

    [Colors:Window]
    BackgroundAlternate=${rgbCsv t.bgDark}
    BackgroundNormal=${rgbCsv t.bg}
    DecorationFocus=${rgbCsv t.focus}
    DecorationHover=${rgbCsv t.accentBright}
    ForegroundActive=${rgbCsv t.accent}
    ForegroundInactive=${rgbCsv t.disabledFg}
    ForegroundLink=${rgbCsv t.link}
    ForegroundNegative=${rgbCsv t.red}
    ForegroundNeutral=${rgbCsv t.yellow}
    ForegroundNormal=${rgbCsv t.fg}
    ForegroundPositive=${rgbCsv t.green}
    ForegroundVisited=${rgbCsv t.accentBright}
  '';

  gtk3CssFor = theme: let
    t = mkThemePalette theme;
  in ''
    @define-color theme_bg_color ${t.bg};
    @define-color theme_fg_color ${t.fg};
    @define-color theme_base_color ${t.bgDark};
    @define-color theme_selected_bg_color ${t.selectionBg};
    @define-color theme_selected_fg_color ${t.selectionFg};
    @define-color theme_unfocused_bg_color ${t.bg};
    @define-color theme_unfocused_fg_color ${t.fgMuted};
    @define-color borders ${t.border};
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
      border-bottom: 1px solid ${t.border};
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
      background-color: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    .view, treeview.view, iconview, list, listbox {
      background-color: ${t.bgDark};
      color: ${t.fg};
    }

    row:selected, .view:selected, treeview.view:selected,
    list row:selected, listbox row:selected {
      background-color: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    row:hover, list row:hover, listbox row:hover {
      background-color: ${t.hoverBg};
    }

    button {
      background-color: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.border};
    }

    button:hover {
      background-color: ${t.activeBg};
    }

    button:active, button:checked {
      background-color: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    button.suggested-action {
      background-color: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    entry, spinbutton {
      background-color: ${t.inputBg};
      color: ${t.fg};
      border: 1px solid ${t.border};
    }

    entry:focus, spinbutton:focus {
      border-color: ${t.focus};
    }

    menu, .menu, .context-menu, popover, popover.background {
      background-color: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.border};
    }

    menu menuitem:hover, popover modelbutton:hover {
      background-color: ${t.activeBg};
    }

    separator {
      background-color: ${t.border};
    }

    scrollbar slider {
      background-color: ${t.border};
    }

    scrollbar slider:hover {
      background-color: ${t.disabledFg};
    }

    check:checked, radio:checked {
      background-color: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    progressbar progress, scale highlight {
      background-color: ${t.selectionBg};
    }

    tooltip, tooltip.background {
      background-color: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.border};
    }

    notebook header tab:checked {
      border-bottom-color: ${t.focus};
    }
  '';

  gtk4CssFor = theme: let
    t = mkThemePalette theme;
  in ''
    @define-color accent_bg_color ${t.selectionBg};
    @define-color accent_fg_color ${t.selectionFg};
    @define-color accent_color ${t.accent};
    @define-color destructive_bg_color ${t.red};
    @define-color destructive_fg_color ${t.dangerFg};
    @define-color success_bg_color ${t.green};
    @define-color success_fg_color ${t.successFg};
    @define-color warning_bg_color ${t.yellow};
    @define-color warning_fg_color ${t.warningFg};
    @define-color error_bg_color ${t.red};
    @define-color error_fg_color ${t.dangerFg};
    @define-color window_bg_color ${t.bg};
    @define-color window_fg_color ${t.fg};
    @define-color view_bg_color ${t.bgDark};
    @define-color view_fg_color ${t.fg};
    @define-color headerbar_bg_color ${t.bgDark};
    @define-color headerbar_fg_color ${t.fg};
    @define-color headerbar_border_color ${t.border};
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
    @define-color scrollbar_outline_color ${t.border};

    * {
      --accent-bg-color: ${t.selectionBg};
      --accent-fg-color: ${t.selectionFg};
      --accent-color: ${t.accent};
      --destructive-bg-color: ${t.red};
      --destructive-fg-color: ${t.dangerFg};
      --success-bg-color: ${t.green};
      --success-fg-color: ${t.successFg};
      --warning-bg-color: ${t.yellow};
      --warning-fg-color: ${t.warningFg};
      --error-bg-color: ${t.red};
      --error-fg-color: ${t.dangerFg};
      --window-bg-color: ${t.bg};
      --window-fg-color: ${t.fg};
      --view-bg-color: ${t.bgDark};
      --view-fg-color: ${t.fg};
      --headerbar-bg-color: ${t.bgDark};
      --headerbar-fg-color: ${t.fg};
      --headerbar-border-color: ${t.border};
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
      border-bottom: 1px solid ${t.border};
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
      background: ${t.activeBg};
      color: ${t.fg};
    }

    headerbar button:active, headerbar button:checked {
      background: ${t.selectionBg};
      color: ${t.selectionFg};
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
      background-color: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    .view, list, listview, columnview, gridview {
      background-color: ${t.bgDark};
      color: ${t.fg};
    }

    list > row:selected, listview > row:selected,
    columnview > row:selected, gridview > child:selected {
      background-color: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    list > row:hover, listview > row:hover,
    columnview > row:hover {
      background-color: ${t.hoverBg};
      color: ${t.fg};
    }

    button {
      background: ${t.surface};
      color: ${t.fg};
    }

    button:hover {
      background: ${t.activeBg};
      color: ${t.fg};
    }

    button:active, button:checked,
    button.suggested-action {
      background: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    button.destructive-action {
      background: ${t.red};
      color: ${t.dangerFg};
    }

    button:disabled {
      color: ${t.fgMuted};
    }

    .suffixes > button {
      background: ${t.inputBg};
      color: ${t.fg};
      border: 1px solid ${t.border};
      transition: background 150ms ease, color 150ms ease, border-color 150ms ease;
    }

    .suffixes > button:hover {
      background: ${t.surface};
      color: ${t.fg};
      border-color: ${t.borderStrong};
    }

    .suffixes > button:active {
      background: ${t.selectionBg};
      color: ${t.selectionFg};
      border-color: ${t.selectionBg};
      transition: background 80ms ease;
    }

    entry, spinbutton, searchbar > revealer > box {
      background: ${t.inputBg};
      color: ${t.fg};
    }

    entry:focus-within, spinbutton:focus-within {
      outline-color: ${t.focus};
    }

    popover > contents, .context-menu {
      background: ${t.surface};
      color: ${t.fg};
      border: 1px solid ${t.border};
    }

    popover modelbutton:hover, popover row:hover,
    .context-menu .activatable:hover {
      background: ${t.activeBg};
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
      background: ${t.border};
    }

    scrollbar > range > trough > slider {
      background: ${t.border};
    }

    scrollbar > range > trough > slider:hover {
      background: ${t.disabledFg};
    }

    check:checked, radio:checked {
      background: ${t.selectionBg};
      color: ${t.selectionFg};
    }

    scale > trough > highlight {
      background: ${t.selectionBg};
    }

    progressbar > trough > progress {
      background: ${t.selectionBg};
    }

    switch:checked {
      background: ${t.selectionBg};
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
    t = mkThemePalette theme;
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
    t = mkThemePalette theme;
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
      user_pref("widget.gtk.native-context-menus", false);
      user_pref("ui.highlight", "${t.accent}");
      user_pref("ui.highlighttext", "${t.selectionFg}");
    '';

    userContent = ''
      @-moz-document url-prefix("about:"), url-prefix("chrome://browser/content/") {
        :root {
          --in-content-page-background: ${t.bg} !important;
          --in-content-page-color: ${t.fg} !important;
          --in-content-primary-button-background: ${t.selectionBg} !important;
          --in-content-primary-button-text-color: ${t.selectionFg} !important;
          --in-content-accent-color: ${t.accent} !important;
          --in-content-box-background: ${t.bgDark} !important;
          --in-content-box-border-color: ${t.border} !important;
          --in-content-border-color: ${t.border} !important;
          --in-content-link-color: ${t.link} !important;
          --in-content-table-background: ${t.bgDark} !important;
          --in-content-item-hover: ${t.hoverBg} !important;
          --in-content-item-selected: ${t.activeBg} !important;
          --newtab-background-color: ${t.bg} !important;
          --newtab-background-color-secondary: ${t.bgDark} !important;
          --newtab-background-card: ${t.surface} !important;
          --newtab-text-primary-color: ${t.fg} !important;
          --newtab-primary-action-background: ${t.selectionBg} !important;
        }
      }

      #root {
        --color-accent-primary: ${firefoxAccent} !important;
        --frame-bg: ${t.bg} !important;
        --frame-fg: var(--color-accent-primary) !important;
        --toolbar-fg: var(--frame-fg) !important;
        --toolbar-fg-active: var(--color-accent-primary) !important;
        --border: ${t.bg} !important;
        --notification-bg: ${t.bg} !important;
        --notification-fg: ${t.fg} !important;
        --ctx-menu-bg: ${t.bg} !important;
        --ctx-menu-fg: var(--color-accent-primary) !important;
        --ctx-menu-separator: ${t.border} !important;
        --popup-bg: ${t.bg} !important;
        --popup-fg: ${t.fg} !important;
        --tabs-normal-fg: color-mix(in oklab, ${firefoxAccent}, transparent 35%) !important;
        --tabs-normal-bg: transparent !important;
        --tabs-activated-fg: var(--color-accent-primary) !important;
        --tabs-activated-bg: color-mix(in oklab, ${firefoxAccent}, transparent 75%) !important;
        --tabs-progress-bg: var(--color-accent-primary) !important;
        --toolbar-bg: ${t.bg} !important;
        --nav-btn-accent: var(--color-accent-primary) !important;

        --s-accent: var(--color-accent-primary) !important;
        --s-frame-bg: ${t.bg} !important;
        --s-frame-fg: var(--color-accent-primary) !important;
        --s-toolbar-bg: ${t.bg} !important;
        --s-toolbar-fg: var(--color-accent-primary) !important;
        --s-toolbar-border: ${t.bg} !important;
        --s-popup-bg: ${t.bg} !important;
        --s-popup-fg: ${t.fg} !important;
        --s-popup-border: ${t.border} !important;
        --s-act-el-bg: color-mix(in oklab, ${firefoxAccent}, transparent 75%) !important;
        --s-act-el-fg: var(--color-accent-primary) !important;
        --s-act-el-border: var(--color-accent-primary) !important;
      }
    '';

    userChrome = ''
      :root {
        --chrome-selection-color: ${t.selectionFg} !important;
        --chrome-selection-background-color: ${t.selectionBg} !important;
        --toolbar-bgcolor: ${t.bg} !important;
        --lwt-accent-color: ${t.bg} !important;
        --lwt-text-color: ${t.fg} !important;
        --lwt-toolbar-field-background-color: ${firefoxDarkBg} !important;
        --lwt-toolbar-field-color: ${t.fg} !important;
        --lwt-toolbar-field-focus-color: ${t.fg} !important;
        --lwt-toolbar-field-border-color: ${t.border} !important;
        --lwt-toolbar-field-highlight: ${t.selectionBg} !important;
        --lwt-toolbar-field-highlight-text: ${t.selectionFg} !important;
        --color-accent-primary: ${firefoxAccent} !important;
        --color-accent-primary-hover: ${firefoxAccent} !important;
        --color-accent-primary-active: ${firefoxAccent} !important;
        --focus-outline-color: var(--color-accent-primary) !important;
        --border-color-selected: var(--color-accent-primary) !important;
        --toolbar-color: var(--color-accent-primary) !important;
        --toolbar-background-color: ${t.bg} !important;
        --toolbox-background-color: ${t.bg} !important;
        --toolbox-text-color: var(--color-accent-primary) !important;
        --toolbox-text-color-inactive: color-mix(in oklab, var(--color-accent-primary), transparent 35%) !important;
        --toolbarbutton-icon-fill: var(--color-accent-primary) !important;
        --toolbarbutton-icon-fill-attention: var(--color-accent-primary) !important;
        --toolbarbutton-background-color-hover: color-mix(in oklab, var(--color-accent-primary), transparent 88%) !important;
        --toolbarbutton-background-color-active: color-mix(in oklab, var(--color-accent-primary), transparent 75%) !important;
        --toolbarbutton-outline-color-hover: color-mix(in oklab, var(--color-accent-primary), transparent 45%) !important;
        --toolbarbutton-outline-color-active: var(--color-accent-primary) !important;
        --toolbarbutton-outline-color-selected: var(--color-accent-primary) !important;
        --toolbar-field-background-color: ${firefoxDarkBg} !important;
        --toolbar-field-focus-background-color: ${firefoxDarkBg} !important;
        --toolbar-field-border-color: ${t.border} !important;
        --toolbar-field-border-color-focus: var(--color-accent-primary) !important;
        --toolbar-field-color: ${t.fg} !important;
        --toolbar-field-focus-color: ${t.fg} !important;
        --toolbar-field-text-color: ${t.fg} !important;
        --toolbar-field-text-color-focus: ${t.fg} !important;
        --urlbar-box-background-color: ${firefoxDarkBg} !important;
        --urlbar-box-background-color-focus: ${firefoxDarkBg} !important;
        --urlbar-box-background-color-hover: ${t.hoverBg} !important;
        --urlbar-box-background-color-active: ${t.activeBg} !important;
        --urlbar-box-text-color: ${t.fg} !important;
        --urlbar-box-text-color-hover: ${t.fg} !important;
        --urlbar-box-bgcolor: ${firefoxDarkBg} !important;
        --urlbarview-background-color-hover: color-mix(in oklab, var(--color-accent-primary), transparent 80%) !important;
        --urlbarview-background-color-selected: color-mix(in oklab, var(--color-accent-primary), transparent 50%) !important;
        --urlbarview-text-color-selected: ${t.selectionFg} !important;
        --urlbarview-text-color-action: var(--color-accent-primary) !important;
        --urlbarview-separator-color: ${t.border} !important;
        --urlbarView-secondary-text-color: color-mix(in oklab, var(--color-accent-primary), transparent 35%) !important;
        --link-color: ${t.link} !important;
        --chrome-content-separator-color: var(--color-accent-primary) !important;
        --arrowpanel-border-color: var(--color-accent-primary) !important;
        --arrowpanel-background: ${t.bg} !important;
        --arrowpanel-color: ${t.fg} !important;
        --arrowpanel-dimmed: ${t.hoverBg} !important;
        --arrowpanel-dimmed-further: ${t.activeBg} !important;
        --panel-background: ${t.bg} !important;
        --panel-background-color: ${t.bg} !important;
        --panel-color: ${t.fg} !important;
        --panel-text-color: ${t.fg} !important;
        --panel-border-color: ${t.border} !important;
        --panel-separator-color: ${t.border} !important;
        --panel-description-color: color-mix(in oklab, ${t.fg}, transparent 30%) !important;
        --panel-item-hover-bgcolor: ${t.hoverBg} !important;
        --panel-item-active-bgcolor: ${t.activeBg} !important;
        --panel-item-hover-color: ${t.fg} !important;
        --panel-item-active-color: ${t.fg} !important;
        --menu-background-color: ${t.bg} !important;
        --menu-color: ${t.fg} !important;
        --menuitem-hover-background-color: ${t.hoverBg} !important;
        --menuitem-disabled-hover-background-color: transparent !important;
        --menuitem-icon-fill: var(--color-accent-primary) !important;
        --text-color-disabled: color-mix(in oklab, ${t.fg}, transparent 55%) !important;
        --button-background-color: ${t.surface} !important;
        --button-background-color-hover: ${t.activeBg} !important;
        --button-background-color-active: color-mix(in oklab, var(--color-accent-primary), transparent 70%) !important;
        --button-text-color: ${t.fg} !important;
        --button-text-color-primary: ${t.selectionFg} !important;
        --input-bgcolor: ${firefoxDarkBg} !important;
        --input-color: ${t.fg} !important;
        --input-border-color: ${t.border} !important;
        --sidebar-background-color: ${t.bg} !important;
        --sidebar-text-color: ${t.fg} !important;
        --sidebar-border-color: ${t.bg} !important;
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

      #navigator-toolbox,
      #titlebar,
      #toolbar-menubar,
      #TabsToolbar,
      #nav-bar,
      #PersonalToolbar,
      toolbar.browser-toolbar {
        background-color: ${t.bg} !important;
        background-image: none !important;
        color: ${t.fg} !important;
      }

      .urlbar-icon,
      .toolbarbutton-icon,
      .searchbar-engine-one-off-item :is(image, .button-icon),
      .urlbarView-button,
      .urlbarView-action-btn {
        fill: var(--color-accent-primary) !important;
        -moz-context-properties: fill, fill-opacity !important;
      }

      .urlbar-input {
        color: ${t.fg} !important;
      }

      .urlbar-background,
      #urlbar:is([focused], [open]) > .urlbar-background,
      #searchbar,
      #searchbar:focus-within,
      #searchbar-new > .urlbar-background {
        background-color: ${firefoxDarkBg} !important;
        border-color: var(--toolbar-field-border-color-focus) !important;
        box-shadow: none !important;
      }

      #urlbar:is([focused], [open]) > .urlbar-input-container,
      #searchbar:focus-within,
      #searchbar-new:is([focused], [open]) > .urlbar-input-container {
        color: ${t.fg} !important;
      }

      .urlbarView-row:is([selected], [row-selectable]:hover),
      .urlbarView-realtime-root:not([selectable]) > .urlbarView-realtime-item:hover,
      .urlbarView-realtime-item[selected] {
        background-color: color-mix(in oklab, ${t.selectionBg}, transparent 35%) !important;
      }

      .urlbarView-row:is([selected], [row-selectable]:hover) :is(
        .urlbarView-title,
        .urlbarView-url,
        .urlbarView-action,
        .urlbarView-explanation,
        .urlbarView-row-body-description,
        .urlbarView-row-body-bottom,
        .urlbarView-overflowable
      ),
      .urlbarView-realtime-item:is(:hover, [selected]) :is(
        .urlbarView-realtime-description-top,
        .urlbarView-realtime-description-bottom
      ) {
        color: ${t.selectionFg} !important;
      }

      #urlbar:is([focused], [open])[breakout-extend] > .urlbar-background {
        border-radius: var(--toolbarbutton-special-border-radius) !important;
      }

      #statuspanel-label {
        background-color: var(--color-accent-primary) !important;
        color: ${t.selectionFg} !important;
      }

      #TabsToolbar,
      #sidebar-main,
      #sidebar-header,
      #sidebar-launcher-splitter {
        display: none !important;
      }

      menupopup,
      panel {
        --panel-background: ${t.bg} !important;
        --panel-background-color: ${t.bg} !important;
        --panel-color: ${t.fg} !important;
        --panel-text-color: ${t.fg} !important;
        --panel-border-color: ${t.border} !important;
        --panel-separator-color: ${t.border} !important;
        --panel-box-shadow: 0 4px 14px ${t.shadow} !important;
        --menuitem-icon-fill: var(--color-accent-primary) !important;
        --menuitem-border-radius: 4px !important;
        --menuitem-padding: 0.45em 0.85em !important;
      }

      menupopup {
        --background-color-canvas: ${t.bg} !important;
        appearance: none !important;
        background: ${t.bg} !important;
        background-color: ${t.bg} !important;
        color: ${t.fg} !important;
        border: 1px solid ${t.border} !important;
        box-shadow: 0 4px 12px ${t.shadow} !important;
      }

      menupopup::part(content),
      panel::part(content) {
        background: ${t.bg} !important;
        background-color: ${t.bg} !important;
        color: ${t.fg} !important;
        border-color: ${t.border} !important;
        box-shadow: 0 4px 14px ${t.shadow} !important;
      }

      menuitem,
      menu,
      menucaption {
        appearance: none !important;
        background-color: transparent !important;
        color: ${t.fg} !important;
        fill: var(--color-accent-primary) !important;
      }

      :is(menuitem, menu):is(:hover, [_moz-menuactive="true"], [selected="true"]):not([disabled="true"]) {
        appearance: none !important;
        background-color: ${t.hoverBg} !important;
        color: ${t.fg} !important;
      }

      :is(menuitem, menu)[disabled="true"],
      :is(menuitem, menu)[disabled="true"] > :is(.menu-text, .menu-accel) {
        color: color-mix(in oklab, ${t.fg}, transparent 55%) !important;
      }

      .menu-icon,
      .menu-accel,
      menupopup > menu::after {
        fill: var(--color-accent-primary) !important;
        color: var(--color-accent-primary) !important;
      }

      menuseparator,
      toolbarseparator {
        border-color: ${t.border} !important;
      }
    '';
  };
in {
  inherit
    hexToRgb
    mkFirefoxTheme
    mkGtkTheme
    mkKittyTheme
    mkThemePalette
    mkThemeRoles
    mkQtTheme
    mkThemeTokens
    promptColorFor
    resolveAppSlots
    rgbCsv
    stripHex
    ;
}
