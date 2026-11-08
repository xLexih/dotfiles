# Battery and power profiles for this machine (i9-14900HX, yt6801 ethernet at
# 3a:00.0, Uniwill chassis; no working charge limit, see docs/power.md).
#
# TLP applies one of three profiles, switchable from the bar's battery icon:
#   performance  (manual)      no limits, performance EPP
#   balanced     (plugged in)  turbo, balance_performance EPP, 240 Hz
#   power-saver  (unplugged)   no turbo, power EPP, iGPU capped, 60 Hz,
#                              no blur/shadows/animations
# Turbo is what costs energy on battery: a fixed CPU job took 2.7x the energy
# with turbo, while idle and light load barely change between profiles.
# Plugging in or unplugging always selects the profile for the new power
# source. Refresh rate and effects are set by the Hyprland session (see
# modules/desktop/hyprland.nix); the rest is TLP and the hook below. TLP is
# the only place for ASPM, audio power save, writeback and Wi-Fi power save:
# it rewrites those on every profile change.
{
  config,
  lib,
  pkgs,
  ...
}: let
  ethernet = "0000:3a:00.0";

  # Runs at boot and whenever TLP applies a profile (it rewrites
  # /run/tlp/last_pwr).
  profileHook = pkgs.writeShellApplication {
    name = "power-profile-hook";
    runtimeInputs = [pkgs.coreutils pkgs.iproute2 config.systemd.package];
    text = ''
      ac=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || echo 1)

      if [ "$ac" = 1 ]; then
        echo ${ethernet} > /sys/bus/pci/drivers/yt6801/bind 2>/dev/null || true
        # In the background: it takes about 2 s to come up.
        systemctl start --no-block nvidia-powerd.service || true
      else
        # Unbound, the NIC can reach D3cold. Dynamic Boost (more GPU power
        # under load; measured 115 -> 120 W) only applies on AC anyway.
        ip link set enp58s0 down 2>/dev/null || true
        echo ${ethernet} > /sys/bus/pci/drivers/yt6801/unbind 2>/dev/null || true
        systemctl stop nvidia-powerd.service || true
      fi
    '';
  };
in {
  services.upower = {
    enable = true;
    # HybridSleep stays suspended, and s2idle draws about 3 W here: the last
    # 2% would run the pack down to its cutoff. Hibernating at 5% leaves about
    # 3.5 Wh in the pack and stops the drain.
    percentageCritical = 8;
    percentageAction = 5;
    criticalPowerAction = "Hibernate";
  };
  # D-Bus activation started it only once the session asked, after
  # WirePlumber had already failed to read the battery level.
  systemd.services.upower.wantedBy = ["multi-user.target"];
  services.thermald.enable = true;

  boot.kernelParams = [
    "cpuidle.governor=teo"
    "rcu_nocbs=all"
    "i915.enable_dc=2"
    "intel_pstate=active"
  ];

  # Closing the lid only turns the panel off (hyprland.lua), so work keeps
  # running. The sleep key (Fn+F1) suspends and hibernates after 30 min.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleSuspendKey = "suspend-then-hibernate";
  };
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";
  # Fn+F1 also sends scancode e078, which the keyboard driver doesn't know
  # and logs on every press.
  services.udev.extraHwdb = ''
    evdev:atkbd:dmi:*
     KEYBOARD_KEY_f8=unknown
  '';

  # Unset, NetworkManager leaves Wi-Fi power save to TLP instead of
  # re-applying its own value on every connect.
  networking.networkmanager.wifi.powersave = lib.mkForce null;

  services.tlp = {
    enable = true;
    # _SAV values fall back to _BAT when unset.
    settings = {
      TLP_AUTO_SWITCH = 1;
      TLP_PROFILE_AC = "BAL";
      TLP_PROFILE_BAT = "SAV";

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      # Full turbo on demand, but it ramps up less eagerly and idles cooler.
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 0;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;
      CPU_HWP_DYN_BOOST_ON_SAV = 0;

      INTEL_GPU_MIN_FREQ_ON_AC = 300;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MIN_FREQ_ON_SAV = 300;

      INTEL_GPU_MAX_FREQ_ON_AC = 1650;
      INTEL_GPU_MAX_FREQ_ON_BAT = 1650;
      INTEL_GPU_MAX_FREQ_ON_SAV = 900;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1650;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1650;
      INTEL_GPU_BOOST_FREQ_ON_SAV = 900;

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      # TLP's own default for _SAV is "default", not the _BAT value.
      PCIE_ASPM_ON_SAV = "powersupersave";
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      # TLP keeps every xhci_hcd controller awake by default. The Thunderbolt
      # port's USB controller then holds the whole Thunderbolt bridge chain and
      # its root port active even with nothing plugged in.
      RUNTIME_PM_ENABLE = "1f:00.0";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      SOUND_POWER_SAVE_ON_AC = 10;
      SOUND_POWER_SAVE_ON_BAT = 10;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
      # Seconds of writes that can be lost on a crash (sets the dirty
      # writeback and expire sysctls); longer lets the disk sleep.
      MAX_LOST_WORK_SECS_ON_AC = 15;
      MAX_LOST_WORK_SECS_ON_BAT = 60;
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_AUDIO = 1;
      USB_EXCLUDE_BTUSB = 0;
      # TLP keeps HID devices awake; the ITE per-key keyboard lighting
      # controller can suspend. (The lightbar, 048d:7001, stays awake
      # because its LED driver holds it; the keyboard itself is PS/2.)
      USB_ALLOWLIST = "048d:600b";
    };
  };

  systemd.paths.power-profile-hook = {
    description = "Apply ethernet and Dynamic Boost settings for the TLP profile";
    wantedBy = ["multi-user.target"];
    pathConfig.PathChanged = "/run/tlp/last_pwr";
  };
  systemd.services.power-profile-hook = {
    after = ["tlp.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe profileHook;
    };
  };

  # Started by the hook on AC instead of holding up boot (it took 2.3 s).
  systemd.services.nvidia-powerd.wantedBy = lib.mkForce [];

  boot.kernel.sysctl."kernel.watchdog" = 0;
}
