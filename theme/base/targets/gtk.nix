# GTK: adw-gtk3 for GTK 3 and libadwaita for GTK 4, recolored the way both
# document it, by overriding libadwaita's named colors in gtk.css (GTK 3 as
# @define-color, libadwaita 1.6+ as CSS variables). Theme, icons, cursor, fonts
# and the dark/light preference go through GSettings, which running apps and
# the settings portal (Firefox, Electron, libadwaita) follow live. gtk.css is
# read when an app starts.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.theme;

  namedColors = theme: let
    t = theme.colors;
  in {
    accent-color = t.accent;
    accent-bg-color = t.selectionBg;
    accent-fg-color = t.selectionFg;
    destructive-color = t.red;
    destructive-bg-color = t.red;
    destructive-fg-color = t.dangerFg;
    success-color = t.green;
    success-bg-color = t.green;
    success-fg-color = t.successFg;
    warning-color = t.yellow;
    warning-bg-color = t.yellow;
    warning-fg-color = t.warningFg;
    error-color = t.red;
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
    sidebar-bg-color = t.bgDark;
    sidebar-fg-color = t.fg;
    sidebar-backdrop-color = t.bgDark;
    secondary-sidebar-bg-color = t.bg;
    secondary-sidebar-fg-color = t.fg;
    secondary-sidebar-backdrop-color = t.bg;
    card-bg-color = t.surface;
    card-fg-color = t.fg;
    dialog-bg-color = t.surface;
    dialog-fg-color = t.fg;
    popover-bg-color = t.surface;
    popover-fg-color = t.fg;
    thumbnail-bg-color = t.surface;
    thumbnail-fg-color = t.fg;
  };

  settingsIni = theme: ''
    [Settings]
    gtk-theme-name=${theme.gtk.name}
    gtk-icon-theme-name=${theme.icons.name}
    gtk-cursor-theme-name=${theme.cursor.name}
    gtk-cursor-theme-size=${toString theme.cursor.size}
    gtk-font-name=${theme.fonts.sans}
    gtk-application-prefer-dark-theme=${lib.boolToString (theme.variant == "dark")}
  '';

  interface = theme: {
    gtk-theme = theme.gtk.name;
    icon-theme = theme.icons.name;
    cursor-theme = theme.cursor.name;
    cursor-size = lib.gvariant.mkInt32 theme.cursor.size;
    font-name = theme.fonts.sans;
    document-font-name = theme.fonts.document;
    monospace-font-name = theme.fonts.mono;
    color-scheme = "prefer-${theme.variant}";
    accent-color = theme.gnomeAccent;
  };

  dconf = "${pkgs.dconf}/bin/dconf";
in {
  modules.theme = {
    render.gtk = theme: let
      colors = namedColors theme;
    in {
      ".gtkrc-2.0" = ''
        gtk-theme-name="${theme.gtk.name}"
        gtk-icon-theme-name="${theme.icons.name}"
        gtk-cursor-theme-name="${theme.cursor.name}"
        gtk-cursor-theme-size=${toString theme.cursor.size}
        gtk-font-name="${theme.fonts.sans}"
      '';
      ".config/gtk-3.0/settings.ini" = settingsIni theme;
      ".config/gtk-4.0/settings.ini" = settingsIni theme;
      ".config/gtk-3.0/gtk.css" = lib.concatStrings (lib.mapAttrsToList (name: value: "@define-color ${lib.replaceStrings ["-"] ["_"] name} ${value};\n") colors);
      ".config/gtk-4.0/gtk.css" = ":root {\n${lib.concatStrings (lib.mapAttrsToList (name: value: "  --${name}: ${value};\n") colors)}}\n";
    };

    # GVariant text, written straight to dconf; GSettings users get notified.
    metadata.gtk = theme: lib.mapAttrs (_: value: toString (lib.gvariant.mkValue value)) (interface theme);

    # One dconf transaction, so apps re-theme once instead of once per key.
    reload.gtk = ''
      theme_get '"[/]", (.gtk | to_entries[] | "\(.key)=\(.value)")' |
        ${dconf} load /org/gnome/desktop/interface/
    '';
  };

  # Defaults for users who never switched; `theme` writes the user's own values.
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings."org/gnome/desktop/interface" =
          interface cfg.themes.${cfg.default}
          // {
            font-antialiasing = "rgba";
            font-hinting = "slight";
            font-rgba-order = "rgb";
          };
      }
    ];
  };

  environment.systemPackages =
    lib.unique (lib.concatMap (theme: [theme.gtk.package theme.icons.package theme.cursor.package]) (lib.attrValues cfg.themes))
    ++ (with pkgs; [
      glib
      gsettings-desktop-schemas
      gnome-themes-extra
      nwg-look
    ]);
}
