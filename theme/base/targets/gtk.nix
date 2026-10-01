# GTK 2/3/4 settings and color overrides, GNOME interface settings.
{
  config,
  lib,
  pkgs,
  ...
}: let
  theme = config.modules.theme.active;
  t = theme.palette // theme.roles;
  dark = theme.variant == "dark";
  preferDark =
    if dark
    then "1"
    else "0";

  settingsIni = ''
    [Settings]
    gtk-theme-name=${theme.gtk.name}
    gtk-icon-theme-name=${theme.icons.name}
    gtk-cursor-theme-name=${theme.cursor.name}
    gtk-cursor-theme-size=${toString theme.cursor.size}
    gtk-font-name=${theme.fonts.sans}
    gtk-application-prefer-dark-theme=${preferDark}
  '';

  gtk2 = ''
    gtk-theme-name="${theme.gtk.name}"
    gtk-icon-theme-name="${theme.icons.name}"
    gtk-cursor-theme-name="${theme.cursor.name}"
    gtk-cursor-theme-size=${toString theme.cursor.size}
    gtk-font-name="${theme.fonts.sans}"
    gtk-application-prefer-dark-theme=${preferDark}
  '';

  gtk3Css = ''
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

  # libadwaita named colors, as @define-color and as CSS variables.
  adwaitaColors = {
    accent-bg-color = t.selectionBg;
    accent-fg-color = t.selectionFg;
    accent-color = t.accent;
    destructive-bg-color = t.red;
    destructive-fg-color = t.dangerFg;
    success-bg-color = t.green;
    success-fg-color = t.successFg;
    warning-bg-color = t.yellow;
    warning-fg-color = t.warningFg;
    error-bg-color = t.red;
    error-fg-color = t.dangerFg;
    window-bg-color = t.bg;
    window-fg-color = t.fg;
    view-bg-color = t.bgDark;
    view-fg-color = t.fg;
    headerbar-bg-color = t.bgDark;
    headerbar-fg-color = t.fg;
    headerbar-border-color = t.border;
    headerbar-backdrop-color = t.bgDark;
    card-bg-color = t.surface;
    card-fg-color = t.fg;
    sidebar-bg-color = t.bgDark;
    sidebar-fg-color = t.fg;
    sidebar-backdrop-color = t.bgDark;
    secondary-sidebar-bg-color = t.bgDark;
    secondary-sidebar-fg-color = t.fg;
    secondary-sidebar-backdrop-color = t.bgDark;
    popover-bg-color = t.surface;
    popover-fg-color = t.fg;
    dialog-bg-color = t.surface;
    dialog-fg-color = t.fg;
  };

  gtk4Css = ''
    ${lib.concatStrings (lib.mapAttrsToList (name: value: "@define-color ${lib.replaceStrings ["-"] ["_"] name} ${value};\n") adwaitaColors)}
    @define-color shade_color rgba(0, 0, 0, 0.25);
    @define-color scrollbar_outline_color ${t.border};

    * {
    ${lib.concatStrings (lib.mapAttrsToList (name: value: "  --${name}: ${value};\n") adwaitaColors)}
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
in {
  dotfiles.files = {
    ".gtkrc-2.0" = gtk2;
    ".config/gtk-3.0/settings.ini" = settingsIni;
    ".config/gtk-3.0/gtk.css" = gtk3Css;
    ".config/gtk-3.0/gtk-dark.css" = gtk3Css;
    ".config/gtk-4.0/settings.ini" = settingsIni;
    ".config/gtk-4.0/gtk.css" = gtk4Css;
    ".config/gtk-4.0/gtk-dark.css" = gtk4Css;
  };

  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        lockAll = true;
        settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = theme.gtk.name;
            icon-theme = theme.icons.name;
            cursor-theme = theme.cursor.name;
            cursor-size = lib.gvariant.mkInt32 theme.cursor.size;
            font-name = theme.fonts.sans;
            document-font-name = theme.fonts.document;
            monospace-font-name = theme.fonts.mono;
            color-scheme = "prefer-${theme.variant}";
            accent-color = theme.gnomeAccent;
            font-antialiasing = "rgba";
            font-hinting = "slight";
            font-rgba-order = "rgb";
          };
          "org/freedesktop/appearance" = {
            color-scheme = lib.gvariant.mkUint32 (
              if dark
              then 1
              else 2
            );
            accent-color = theme.gnomeAccent;
          };
        };
      }
    ];
  };

  environment.sessionVariables = {
    GTK_THEME = theme.gtk.name;
    XCURSOR_THEME = theme.cursor.name;
    XCURSOR_SIZE = toString theme.cursor.size;
  };

  environment.systemPackages = with pkgs; [
    theme.gtk.package
    theme.icons.package
    theme.cursor.package
    glib
    gsettings-desktop-schemas
    gnome-themes-extra
    nwg-look
  ];
}
