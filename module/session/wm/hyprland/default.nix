{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.session.hyprland;
in {
  options.modules.session.hyprland = {
    enable = lib.mkEnableOption "Hyprland wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    programs.xwayland.enable = true;

    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.hyprland.enableGnomeKeyring = true;

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk # file picker for GTK apps
      ];
      config.common = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
    };

    environment.systemPackages = with pkgs; [
      rofi # app launcher
      dunst # notification daemon
      libnotify # send notifications
      awww # wallpaper manager
      wl-clipboard # clipboard copy/paste
      cliphist # clipboard history
      grim # screenshot capture
      hyprshot # screenshot helper
      slurp # region selection
      brightnessctl # backlight control
      playerctl # media playback control
      pamixer # volume control
      hypridle # idle management
      hyprlock # screen locker
      hyprpicker # color picker
      hyprcursor # cursor engine
      wev # input event debugger
      egl-wayland # EGL wayland support
    ];

    environment.variables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      MOZ_ENABLE_WAYLAND = "1";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      GTK_USE_PORTAL = "1";
    };
  };
}
