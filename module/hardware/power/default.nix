{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.power;
  cpuVendor = config.modules.hardware.cpu.vendor;

  powerSwitchScript = pkgs.writeShellScript "power-profile-switch" ''
    AC_STATE=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || echo "1")

    # Find the active Hyprland session
    HYPR_SOCKET=$(find /run/user -name ".socket.sock" -path "*/hypr/*" 2>/dev/null | head -1)
    if [ -z "$HYPR_SOCKET" ]; then
      HYPR_SOCKET=$(find /tmp/hypr -name ".socket.sock" 2>/dev/null | head -1)
    fi

    if [ -n "$HYPR_SOCKET" ]; then
      export HYPRLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$HYPR_SOCKET")")
      HYPR_USER=$(stat -c '%U' "$HYPR_SOCKET")
      HYPRCTL="${pkgs.hyprland}/bin/hyprctl"

      # Get current monitor state and only change the refresh rate
      MONITOR_JSON=$(su - "$HYPR_USER" -c "$HYPRCTL monitors -j" 2>/dev/null)
      if [ -n "$MONITOR_JSON" ]; then
        if [ "$AC_STATE" = "1" ]; then
          TARGET_RATE="240"
        else
          TARGET_RATE="60"
        fi

        # Parse each eDP monitor and reconstruct with new rate
        echo "$MONITOR_JSON" | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP")) | "\(.name),\(.width)x\(.height)@'"$TARGET_RATE"',\(.x)x\(.y),\(.scale)"' | while read -r line; do
          su - "$HYPR_USER" -c "$HYPRCTL keyword monitor \"$line\"" 2>/dev/null
        done

        # Toggle blur and shadows based on power state
        if [ "$AC_STATE" = "1" ]; then
          su - "$HYPR_USER" -c "$HYPRCTL keyword decoration:blur:enabled true" 2>/dev/null
          su - "$HYPR_USER" -c "$HYPRCTL keyword decoration:shadow:enabled true" 2>/dev/null
        else
          su - "$HYPR_USER" -c "$HYPRCTL keyword decoration:blur:enabled false" 2>/dev/null
          su - "$HYPR_USER" -c "$HYPRCTL keyword decoration:shadow:enabled false" 2>/dev/null
        fi
      fi
    fi

    # nvidia-powerd: only useful on AC when dGPU is active
    if [ "$AC_STATE" = "1" ]; then
      systemctl start nvidia-powerd.service 2>/dev/null || true
    else
      systemctl stop nvidia-powerd.service 2>/dev/null || true
    fi
  '';
in {
  options.modules.hardware.power = {
    enable = lib.mkEnableOption "laptop power management with TLP";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cpuVendor != null;
        message = "modules.hardware.power.enable requires modules.hardware.cpu.vendor to be set in the host config.";
      }
    ];

    services.power-profiles-daemon.enable = false;
    services.upower.enable = true;
    services.thermald.enable = cpuVendor == "intel";

    boot.kernelParams =
      [
        "pcie_aspm=powersupersave"
        "mem_sleep_default=deep"
        "nvme_core.default_ps_max_latency_us=5500"
        "snd_hda_intel.power_save=5"
        "snd_hda_intel.power_save_controller=Y"
      ]
      ++ lib.optionals (cpuVendor == "intel") [
        "intel_pstate=active"
      ];

    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
    };

    networking.networkmanager.wifi.powersave = lib.mkForce true;

    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        SCHED_POWERSAVE_ON_BAT = 1;
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        RUNTIME_PM_DRIVER_PM_ON_BAT = "auto";
        RUNTIME_PM_DRIVER_PM_ALL = 1;

        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        SATA_LINKPWR_ON_AC = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
        AHCI_RUNTIME_PM_ON_AC = "on";
        AHCI_RUNTIME_PM_ON_BAT = "auto";

        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_AUDIO = 1;
        USB_EXCLUDE_BTUSB = 0;

        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 85;
      };
    };

    boot.kernel.sysctl = {
      "vm.laptop_mode" = 5;
      "vm.dirty_writeback_centisecs" = 6000;
    };

    systemd.services.power-profile-switch = {
      description = "Switch power profile on AC/battery change";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = powerSwitchScript;
      };
    };

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="auto"
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl start power-profile-switch.service"
    '';
  };
}
