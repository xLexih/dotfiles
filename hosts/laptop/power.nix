# Battery and power profiles for this machine (i9-14900HX: P-cores are CPUs
# 0-15, E-cores 16-31; yt6801 ethernet at 3a:00.0).
#
# TLP applies one of three profiles, switchable from the bar's battery icon:
#   performance  (plugged in)  no limits
#   balanced     (manual)      all cores, turbo, balance_power EPP, 144 Hz
#   power-saver  (unplugged)   E-cores only, no turbo, iGPU capped, 60 Hz,
#                              no blur/shadows/animations
# Plugging in or unplugging always selects the profile for the new power
# source. Refresh rate and effects are set by the Hyprland session (see
# modules/desktop/hyprland.nix); the rest is TLP and the hook below.
{
  config,
  lib,
  pkgs,
  ...
}: let
  ethernet = "0000:3a:00.0";

  # TLP writes "<profile> <power source>" to /run/tlp/last_pwr whenever it
  # applies a profile: 0 performance, 1 balanced, 2 power-saver.
  profileHook = pkgs.writeShellApplication {
    name = "power-profile-hook";
    runtimeInputs = [pkgs.coreutils pkgs.iproute2 config.systemd.package];
    text = ''
      read -r profile _ < /run/tlp/last_pwr
      ac=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || echo 1)

      online=1
      [ "$profile" = 2 ] && online=0
      for cpu in $(seq 1 15); do
        echo "$online" > "/sys/devices/system/cpu/cpu$cpu/online" 2>/dev/null || true
      done

      if [ "$ac" = 1 ]; then
        echo ${ethernet} > /sys/bus/pci/drivers/yt6801/bind 2>/dev/null || true
        systemctl start nvidia-powerd.service || true
      else
        # Unbound, the NIC can reach D3cold. Dynamic Boost only matters for
        # gaming on AC and keeps the NVIDIA GPU busy.
        ip link set enp58s0 down 2>/dev/null || true
        echo ${ethernet} > /sys/bus/pci/drivers/yt6801/unbind 2>/dev/null || true
        systemctl stop nvidia-powerd.service || true
      fi
    '';
  };
in {
  services.upower.enable = true;
  services.thermald.enable = true;

  boot.kernelParams = [
    "pcie_aspm=powersupersave"
    "nvme_core.default_ps_max_latency_us=5500"
    "snd_hda_intel.power_save=10"
    "snd_hda_intel.power_save_controller=Y"
    "cpuidle.governor=teo"
    "rcu_nocbs=all"
    "i915.enable_dc=2"
    "intel_pstate=active"
  ];

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };

  networking.networkmanager.wifi.powersave = lib.mkForce true;

  services.tlp = {
    enable = true;
    # _SAV values fall back to _BAT when unset.
    settings = {
      TLP_AUTO_SWITCH = 1;
      TLP_PROFILE_AC = "PRF";
      TLP_PROFILE_BAT = "SAV";

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 0;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;
      CPU_HWP_DYN_BOOST_ON_SAV = 0;

      INTEL_GPU_MAX_FREQ_ON_AC = 1650;
      INTEL_GPU_MAX_FREQ_ON_BAT = 1650;
      INTEL_GPU_MAX_FREQ_ON_SAV = 900;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1650;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1650;
      INTEL_GPU_BOOST_FREQ_ON_SAV = 900;

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_AUDIO = 1;
      USB_EXCLUDE_BTUSB = 0;

      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 85;
    };
  };

  systemd.paths.power-profile-hook = {
    description = "Apply core, NIC and Dynamic Boost settings for the TLP profile";
    wantedBy = ["multi-user.target"];
    pathConfig.PathChanged = "/run/tlp/last_pwr";
  };
  systemd.services.power-profile-hook.serviceConfig = {
    Type = "oneshot";
    ExecStart = lib.getExe profileHook;
  };

  boot.kernel.sysctl = {
    "vm.laptop_mode" = 5;
    "vm.dirty_writeback_centisecs" = 6000;
    "vm.dirty_expire_centisecs" = 6000;
    "kernel.watchdog" = 0;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="auto"
    # ITE keyboard controllers block package C-states unless autosuspended.
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="048d", ATTR{idProduct}=="8291", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="048d", ATTR{idProduct}=="8233", ATTR{power/control}="auto"
  '';
}
