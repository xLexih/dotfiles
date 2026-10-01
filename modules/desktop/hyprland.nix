{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.hyprland;

  # Session services start with Hyprland and stop when it exits.
  sessionService = description: command: {
    inherit description;
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    wantedBy = ["hyprland-session.target"];
    serviceConfig = {
      ExecStart = command;
      Restart = "on-failure";
      Slice = "session.slice";
    };
  };

  # Turns the blue-light filter on (4500 K) or off until the next scheduled
  # profile in ~/.config/hypr/hyprsunset.conf.
  nightLight = pkgs.writeShellApplication {
    name = "night-light";
    runtimeInputs = [config.programs.hyprland.package];
    text = ''
      if [ "$(hyprctl hyprsunset identity get)" = false ]; then
        hyprctl hyprsunset identity true
      else
        hyprctl hyprsunset temperature 4500
        hyprctl hyprsunset identity false
      fi
    '';
  };
in {
  options.modules.desktop.hyprland.enable = lib.mkEnableOption "the Hyprland desktop";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;
    security.pam.services = {
      login.enableGnomeKeyring = true;
      hyprland.enableGnomeKeyring = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-hyprland xdg-desktop-portal-gtk];
      config.common = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
    };

    # Started and stopped from hyprland.lua so user services can bind to the session.
    systemd.user.targets.hyprland-session = {
      description = "Hyprland compositor session";
      documentation = ["man:systemd.special(7)"];
      bindsTo = ["graphical-session.target"];
      wants = ["graphical-session-pre.target"];
      after = ["graphical-session-pre.target"];
    };

    systemd.user.services = {
      swayosd = sessionService "Volume and brightness OSD" "${pkgs.swayosd}/bin/swayosd-server --style %h/.config/swayosd/style.css";
      hyprsunset = sessionService "Blue-light filter" (lib.getExe pkgs.hyprsunset);
    };

    # Lets the video group (and swayosd) change the backlight.
    services.udev.packages = [pkgs.swayosd];

    environment.systemPackages = with pkgs; [
      awww # wallpaper daemon
      brightnessctl
      cliphist
      dunst
      egl-wayland
      grim
      hyprcursor
      hypridle
      hyprlock
      hyprpicker
      hyprshot
      hyprsunset
      libnotify
      nightLight
      pamixer
      playerctl
      quickshell
      rofi
      satty # screenshot annotation
      slurp
      swayosd
      wev
      wl-clipboard
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      MOZ_ENABLE_WAYLAND = "1";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland;xcb";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      GTK_USE_PORTAL = "1";
    };
  };
}
