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

  # Follows the system power profile: internal panels drop to 144 Hz on
  # balanced and to their lowest rate on power-saver, which also turns off
  # blur, shadows and animations. Leaving power-saver reloads the config.
  powerProfileSession = pkgs.writeShellApplication {
    name = "power-profile-session";
    runtimeInputs = [config.programs.hyprland.package pkgs.glib pkgs.gnused pkgs.jq];
    text = ''
      dest=(--system --dest org.freedesktop.UPower.PowerProfiles --object-path /org/freedesktop/UPower/PowerProfiles)

      profile() {
        gdbus call "''${dest[@]}" --method org.freedesktop.DBus.Properties.Get \
          org.freedesktop.UPower.PowerProfiles ActiveProfile | sed -E "s/.*'(.*)'.*/\1/"
      }

      # $1: highest refresh rate allowed, 0 for the fastest mode, -1 for the slowest.
      panels() {
        hyprctl monitors -j | jq -r --argjson cap "$1" '
          .[] | select(.name | startswith("eDP")) | . as $m
          | [.availableModes[] | capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)Hz$")
             | select((.w | tonumber) == $m.width and (.h | tonumber) == $m.height) | .r | tonumber] as $rates
          | (if $cap == 0 then ($rates | max)
             elif $cap < 0 then ($rates | min)
             else ([$rates[] | select(. <= $cap)] | max) // ($rates | min) end) as $rate
          | select((($rate - .refreshRate) | fabs) > 0.5)
          | "hl.monitor({ output = \(.name | @json), mode = \("\(.width)x\(.height)@\($rate)" | @json), position = \("\(.x)x\(.y)" | @json), scale = \(.scale) })"' |
          while read -r monitor; do hyprctl eval "$monitor" >/dev/null; done
      }

      last=performance # the config's own settings
      apply() {
        current=$(profile) || return 0
        [ "$current" = "$last" ] && return 0
        [ "$last" = power-saver ] && hyprctl reload >/dev/null
        case "$current" in
          performance) panels 0 ;;
          balanced) panels 144 ;;
          power-saver)
            hyprctl eval 'hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })' >/dev/null
            panels -1
            ;;
        esac
        last=$current
      }

      apply
      gdbus monitor "''${dest[@]}" | while read -r line; do
        case "$line" in *ActiveProfile*) apply ;; esac
      done
    '';
  };
in {
  options.modules.desktop.hyprland.enable = lib.mkEnableOption "the Hyprland desktop";

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;
    security.pam.services = {
      login.enableGnomeKeyring = true;
      hyprland.enableGnomeKeyring = true;
    };

    # programs.hyprland already adds its portal, built against the configured
    # Hyprland; listing pkgs.xdg-desktop-portal-hyprland again would install a
    # second build with the same unit and D-Bus names.
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
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
      # Restores the last wallpaper by itself; `theme wallpaper <image>` sets one.
      awww = sessionService "Wallpaper" "${pkgs.awww}/bin/awww-daemon";
      swayosd = sessionService "Volume and brightness OSD" "${pkgs.swayosd}/bin/swayosd-server --style %h/.config/swayosd/style.css";
      hyprsunset = sessionService "Blue-light filter" (lib.getExe pkgs.hyprsunset);
      power-profile-session = sessionService "Display settings for the power profile" (lib.getExe powerProfileSession);
    };

    # Lets the video group (and swayosd) change the backlight.
    services.udev.packages = [pkgs.swayosd];

    environment.systemPackages = with pkgs; [
      awww
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
