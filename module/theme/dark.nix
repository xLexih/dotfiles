{
  config,
  pkgs,
  ...
}: {
  # Enable DConf for Gnome/GTK settings management
  programs.dconf.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [xdg-desktop-portal-gtk];
  };
  # System-wide dark theme settings using gsettings
  systemd.user.targets.gsettings = {
    description = "Update gsettings";
    wants = ["graphical-session-pre.target"];
    after = ["graphical-session-pre.target"];
  };
  systemd.user.services.gsettings = {
    description = "Set gsettings";
    partOf = ["graphical-session.target"];
    script = ''
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = ["graphical-session.target"];
  };

  # GTK configuration
  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    GTK2_RC_FILES = "/etc/gtk-2.0/gtkrc";
    AD_DISABLE_PORTAL = "1"; # Forces some darkmode stuff
  };

  environment.etc = {
    "gtk-2.0/gtkrc".text = ''
      gtk-theme-name="Adwaita-dark"
      gtk-application-prefer-dark-theme=1
    '';
    "gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-theme-name=Adwaita-dark
      gtk-application-prefer-dark-theme=1
    '';
  };

  # QT configuration
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark"; # Simple string value
  };

  environment.systemPackages = with pkgs; [
    gnome-themes-extra
    adwaita-qt
    glib # For gsettings
  ];
}
