{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.power;
  cpuVendor = config.modules.hardware.cpu.vendor;

  powerSwitchScript = pkgs.writeShellScript "power-profile-switch" ''
    AC_STATE=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC0/online 2>/dev/null || echo "1")

    # HWP dynamic boost
    echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null || true

    # P-cores (0-15) off on battery, E-cores (16-31) stay
    if [ "$AC_STATE" = "1" ]; then
      for cpu in $(${pkgs.coreutils}/bin/seq 1 15); do
        echo 1 > /sys/devices/system/cpu/cpu$cpu/online 2>/dev/null || true
      done
      # iGPU: full clock on AC
      echo 1650 > /sys/class/drm/card1/gt_max_freq_mhz 2>/dev/null || true
      echo 1650 > /sys/class/drm/card1/gt_boost_freq_mhz 2>/dev/null || true
    else
      for cpu in $(${pkgs.coreutils}/bin/seq 1 15); do
        echo 0 > /sys/devices/system/cpu/cpu$cpu/online 2>/dev/null || true
      done
      # iGPU: cap at 900MHz on battery
      echo 900 > /sys/class/drm/card1/gt_max_freq_mhz 2>/dev/null || true
      echo 900 > /sys/class/drm/card1/gt_boost_freq_mhz 2>/dev/null || true
    fi

    # Find the active Hyprland session via /run/user/*/hypr/
    HYPR_SOCKET=$(${pkgs.findutils}/bin/find /run/user -name ".socket.sock" -path "*/hypr/*" 2>/dev/null | ${pkgs.coreutils}/bin/head -1)

    if [ -n "$HYPR_SOCKET" ]; then
      INSTANCE_DIR=$(${pkgs.coreutils}/bin/dirname "$HYPR_SOCKET")
      export HYPRLAND_INSTANCE_SIGNATURE=$(${pkgs.coreutils}/bin/basename "$INSTANCE_DIR")
      HYPR_UID=$(${pkgs.coreutils}/bin/stat -c '%u' "$HYPR_SOCKET")
      export XDG_RUNTIME_DIR="/run/user/$HYPR_UID"
      HYPRCTL="${pkgs.hyprland}/bin/hyprctl"

      MONITOR_JSON=$($HYPRCTL monitors -j 2>/dev/null)
      if [ -n "$MONITOR_JSON" ]; then
        if [ "$AC_STATE" = "1" ]; then
          TARGET_RATE="240"
        else
          TARGET_RATE="60"
        fi

        echo "$MONITOR_JSON" | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("eDP")) | "\(.name),\(.width)x\(.height)@'"$TARGET_RATE"',\(.x)x\(.y),\(.scale)"' | while read -r line; do
          $HYPRCTL keyword monitor "$line" 2>/dev/null
        done

        if [ "$AC_STATE" = "1" ]; then
          $HYPRCTL keyword decoration:blur:enabled true 2>/dev/null
          $HYPRCTL keyword decoration:shadow:enabled true 2>/dev/null
          $HYPRCTL keyword animations:enabled true 2>/dev/null
          $HYPRCTL keyword render:direct_scanout false 2>/dev/null
        else
          $HYPRCTL keyword decoration:blur:enabled false 2>/dev/null
          $HYPRCTL keyword decoration:shadow:enabled false 2>/dev/null
          $HYPRCTL keyword animations:enabled false 2>/dev/null
          $HYPRCTL keyword render:direct_scanout true 2>/dev/null
        fi
      fi
    fi

    # yt6801: unbind on battery for PCI D3cold
    if [ "$AC_STATE" = "1" ]; then
      echo "0000:3a:00.0" > /sys/bus/pci/drivers/yt6801/bind 2>/dev/null || true
      ${pkgs.systemd}/bin/systemctl start nvidia-powerd.service 2>/dev/null || true
    else
      ${pkgs.iproute2}/bin/ip link set enp58s0 down 2>/dev/null || true
      echo "0000:3a:00.0" > /sys/bus/pci/drivers/yt6801/unbind 2>/dev/null || true
      ${pkgs.systemd}/bin/systemctl stop nvidia-powerd.service 2>/dev/null || true
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
        "nvme_core.default_ps_max_latency_us=5500"
        "snd_hda_intel.power_save=10"
        "snd_hda_intel.power_save_controller=Y"
        "cpuidle.governor=teo"
        "rcu_nocbs=all"
        "i915.enable_dc=2"
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
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 1;

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
      "vm.dirty_expire_centisecs" = 6000;
      "kernel.watchdog" = 0;
    };

    systemd.tmpfiles.rules = [
      "w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise"
    ];

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
      # ITE keyboard controllers: force autosuspend (prevents package C-state blocking)
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="048d", ATTR{idProduct}=="8291", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="048d", ATTR{idProduct}=="8233", ATTR{power/control}="auto"
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl start power-profile-switch.service"
    '';
  };
}
