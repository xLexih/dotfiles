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

  # Follows the system power profile: internal panels drop to their lowest
  # rate on power-saver, which also turns off blur, shadows and animations.
  # Leaving power-saver restores the fastest rate and reloads the config.
  powerProfileSession = pkgs.writeShellApplication {
    name = "power-profile-session";
    runtimeInputs = [config.programs.hyprland.package pkgs.glib pkgs.gnused pkgs.jq];
    text = ''
      dest=(--system --dest org.freedesktop.UPower.PowerProfiles --object-path /org/freedesktop/UPower/PowerProfiles)

      profile() {
        gdbus call "''${dest[@]}" --method org.freedesktop.DBus.Properties.Get \
          org.freedesktop.UPower.PowerProfiles ActiveProfile | sed -E "s/.*'(.*)'.*/\1/"
      }

      # $1: "max" for the fastest mode, "min" for the slowest.
      panels() {
        hyprctl monitors -j | jq -r --arg pick "$1" '
          .[] | select(.name | startswith("eDP")) | . as $m
          | [.availableModes[] | capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)Hz$")
             | select((.w | tonumber) == $m.width and (.h | tonumber) == $m.height) | .r | tonumber] as $rates
          | (if $pick == "max" then ($rates | max) else ($rates | min) end) as $rate
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
          performance | balanced) panels max ;;
          power-saver)
            hyprctl eval 'hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })' >/dev/null
            panels min
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

  # Hyprland is started with `start-hyprland` from a TTY login. On hybrid
  # laptops the wrapper first lets the compositor drive displays attached to
  # the NVIDIA GPU (see compositorShell in nvidia.nix).
  inherit (config.modules.hardware.graphics.nvidia) compositorShell;
  startHyprland = pkgs.writeShellScriptBin "start-hyprland" ''
    ${compositorShell}
    exec ${config.programs.hyprland.package}/bin/start-hyprland "$@"
  '';

  # At shutdown logind stops the login session (Hyprland, Xwayland) and the
  # user manager at the same time, so session services crashed on the
  # vanishing display. Run under a delay lock, this stops them first when
  # logind announces the shutdown.
  stopSessionOnShutdown = pkgs.writeShellApplication {
    name = "stop-session-on-shutdown";
    runtimeInputs = [pkgs.glib config.systemd.package];
    text = ''
      while read -r line; do
        case "$line" in
          *"PrepareForShutdown (true"*)
            systemctl --user stop graphical-session.target
            exit 0
            ;;
        esac
      done < <(gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1)
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
      # The password dialog for privileged actions in GUI apps (mounting
      # disks, virt-manager, fwupd).
      hyprpolkitagent = sessionService "Polkit authentication agent" "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      session-shutdown = {
        description = "Stop the graphical session before shutdown";
        wantedBy = ["hyprland-session.target"];
        serviceConfig = {
          ExecStart = "${config.systemd.package}/bin/systemd-inhibit --what=shutdown --mode=delay --who=Hyprland --why='Stopping session services' ${lib.getExe stopSessionOnShutdown}";
          Slice = "session.slice";
        };
      };
      # PAM unlocks the login keyring at login, but a daemon it starts itself
      # quits after two minutes unless the session initializes it, which only
      # GNOME's autostart does. Started with the user manager instead, the
      # daemon is already running when PAM unlocks it.
      gnome-keyring = {
        description = "GNOME Keyring";
        wantedBy = ["default.target"];
        serviceConfig = {
          ExecStart = "/run/wrappers/bin/gnome-keyring-daemon --foreground --components=secrets --control-directory=%t/keyring";
          # Login waits for the user manager to start, so PAM finds the socket.
          ExecStartPost = "${pkgs.bash}/bin/sh -c 'until [ -S %t/keyring/control ]; do sleep 0.05; done'";
          TimeoutStartSec = 5;
          Restart = "on-failure";
        };
      };
    };

    # The OSD server gets Caps/Num/Scroll Lock key events from this root
    # backend over D-Bus.
    services.dbus.packages = [pkgs.swayosd];
    systemd.services.swayosd-libinput-backend = {
      description = "SwayOSD LibInput backend";
      wantedBy = ["graphical.target"];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.erikreider.swayosd";
        ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
        Restart = "on-failure";
      };
    };

    # Lets the video group (and swayosd) change the backlight.
    services.udev.packages = [pkgs.swayosd];

    environment.systemPackages = with pkgs;
      lib.optional (compositorShell != "") (lib.hiPrio startHyprland)
      ++ [
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
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      CLUTTER_BACKEND = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      GTK_USE_PORTAL = "1";
    };
  };
}
