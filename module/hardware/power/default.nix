{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.power;
  cpuVendor = config.modules.hardware.cpu.vendor;
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

        SATA_LINKPWR_ON_AC = "med_power_with_dipm"; # balanced sata power saving
        SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
        AHCI_RUNTIME_PM_ON_AC = "on";
        AHCI_RUNTIME_PM_ON_BAT = "auto";

        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_AUDIO = 1; # prevent audio device autosuspend
        USB_EXCLUDE_BTUSB = 0;

        START_CHARGE_THRESH_BAT0 = 75; # extends battery lifespan
        STOP_CHARGE_THRESH_BAT0 = 85;
      };
    };

    powerManagement.powertop.enable = true; # auto-tune power on boot

    boot.kernel.sysctl = {
      "vm.laptop_mode" = 5; # delay disk writes on battery
      "vm.dirty_writeback_centisecs" = 6000; # flush every 60s
    };

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="auto"
    '';
  };
}
