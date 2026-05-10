{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.theme;
in
{
  config = lib.mkIf (cfg.enable && cfg.name == "dark") {
    programs.dconf.enable = true;
    programs.dconf.profiles.user.databases = [
      {
        lockAll = true;
        settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = "adw-gtk3-dark";
            icon-theme = "Papirus-Dark";
            font-name = "Sans Regular 11";
            document-font-name = "Sans Regular 11";
            monospace-font-name = "Monospace Regular 12";
            color-scheme = "prefer-dark";
          };
        };
      }
    ];

    systemd.user.targets.gsettings = {
      description = "Update gsettings for dark theme";
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.gsettings = {
      description = "Set gsettings for dark theme";
      environment = {
        DBUS_SESSION_BUS_ADDRESS = "%t/bus";
      };
      partOf = [ "graphical-session.target" ];
      script = ''
        export GSETTINGS_SCHEMA_DIR="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.pname}-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas";

        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
        ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "graphical-session.target" ];
    };

    environment.etc."xdg/gtk-4.0/assets".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/assets";
    environment.etc."xdg/gtk-4.0/gtk.css".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk.css";
    environment.etc."xdg/gtk-4.0/gtk-dark.css".source =
      "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk-dark.css";

    environment.etc = {
      "gtk-2.0/gtkrc".text = ''
        gtk-theme-name="Adwaita-dark"
        gtk-icon-theme-name="Adwaita"
        gtk-cursor-theme-name="Adwaita"
        gtk-application-prefer-dark-theme=1
      '';
      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=Adwaita-dark
        gtk-icon-theme-name=Adwaita
        gtk-cursor-theme-name=Adwaita
        gtk-application-prefer-dark-theme=1
      '';
      "gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=Adwaita-dark
        gtk-icon-theme-name=Adwaita
        gtk-cursor-theme-name=Adwaita
        gtk-application-prefer-dark-theme=1
      '';
    };

    environment.variables = {
      GTK_THEME = "Adwaita:dark";
      GTK2_RC_FILES = "/etc/gtk-2.0/gtkrc";
      GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.pname}-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas";
      MOZ_USE_XINPUT2 = "1";
    };

    environment.etc."xdg/Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=AdwaitaDark
      useDarkTheme=true
    '';

    environment.etc."xdg/Kvantum/AdwaitaDark/AdwaitaDark.kvconfig".source =
      "${pkgs.qt6Packages.qtstyleplugin-kvantum}/share/Kvantum/AdwaitaDark/AdwaitaDark.kvconfig";

    environment.systemPackages = with pkgs; [
      nordic
      glib
      gnome-themes-extra
      adwaita-icon-theme
      adw-gtk3
      papirus-icon-theme
      adwaita-qt
      nwg-look
      gsettings-desktop-schemas
      qt6Packages.qt6ct
      qt6Packages.qtstyleplugin-kvantum
    ];
  };
}
