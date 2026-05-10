{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.program.app.hyprland;
in {
  options.program.app.hyprland = {
    enable = lib.mkEnableOption "Hyprland compositor and related tools";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    programs.xwayland.enable = true;

    services.gnome.gnome-keyring.enable = true;

    security.polkit.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.hyrpland.enableGnomeKeyring = true;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
    services.xserver = {
      enable = true;
      displayManager.lightdm = {
        enable = false;
        extraConfig = ''
          logind-check-graphical=true
        '';
      };
    };
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
    };
    environment.systemPackages = with pkgs; [
      egl-wayland
      wl-clipboard
      kitty
      hyprpaper
      rofi
      waybar
      gnome-icon-theme
      hyprshot
      grim
      slurp
      hyprpicker
      hyprcursor
      gtk4
      nwg-look
      bibata-cursors
      adwaita-icon-theme
      nordic
      wev
      brightnessctl
    ];

    environment.variables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      GTK_USE_PORTAL = "1";
      NIXOS_OZONE_WL = "1";

      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      MOZ_ENABLE_WAYLAND = "1";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };
  };
}
