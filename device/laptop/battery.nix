{
  config,
  lib,
  pkgs,
  ...
}: {
  options.batteryOptimize = {
    enable = lib.mkEnableOption "Enable aggressive battery optimization for laptop";

    undervolt = {
      enable = lib.mkEnableOption "Enable CPU undervolting (requires intel-undervolt)";
      voltageOffset = lib.mkOption {
        type = lib.types.int;
        default = -50;
        description = "Voltage offset in mV (negative = undervolt). Default -50mV conservative.";
      };
    };

    aggressivePowerSave = {
      enable = lib.mkEnableOption "Enable most aggressive power saving (may impact performance)";
      maxCpuFreqBat = lib.mkOption {
        type = lib.types.int;
        default = 2000000;
        description = "Max CPU frequency on battery in Hz. Default 2GHz.";
      };
    };

    gpuPowerStates = {
      enable = lib.mkEnableOption "Enable Intel GPU deep power states";
    };

    teoIdleGovernor = {
      enable = lib.mkEnableOption "Use TEO idle governor (more aggressive power saving)";
    };

    coreParking = {
      enable = lib.mkEnableOption "Park E-cores on battery (use P-cores primarily)";
      parkEcoreList = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [24 25 26 27 28 29 30 31];
        description = "List of CPU indices to park on battery (default: half of E-cores).";
      };
    };
  };

  config = let
    cfg = config.batteryOptimize;
  in
    lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        intel-gpu-tools
        powertop
      ];

      boot.kernelParams =
        [
          "intel_pstate=active"
          "pcie_aspm=powersupersave"
          "usbcore.autosuspend=2"
          "nmi_watchdog=0"
          "processor.max_cstate=5"
        ]
        ++ lib.optionals cfg.gpuPowerStates.enable [
          "i915.enable_fbc=1"
          "i915.enable_psr=1"
          "i915.enable_dc=2"
          "i915.enable_guc=2"
        ];

      boot.kernelModules = ["msr"];

      boot.kernel.sysctl = {
        "vm.dirty_writeback_centisecs" = 6000;
        "vm.laptop_mode" = 5;
        "vm.swappiness" = 10;
        "kernel.nmi_watchdog" = 0;
      };

      systemd.tmpfiles.rules =
        [
          "w /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq - - - - 800000"
          "w /sys/module/snd_hda_intel/parameters/power_save - - - - 1"
          "w /sys/module/snd_hda_intel/parameters/power_save_controller - - - - Y"
        ]
        ++ lib.optionals cfg.teoIdleGovernor.enable [
          "w /sys/devices/system/cpu/cpuidle/current_governor - - - - teo"
        ];

      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
        ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
        ACTION=="add", SUBSYSTEM=="usb", TEST=="power/autosuspend", ATTR{power/autosuspend}="2"
      '';

      services.tlp = {
        enable = true;
        settings = let
          maxFreq =
            if cfg.aggressivePowerSave.enable
            then cfg.aggressivePowerSave.maxCpuFreqBat
            else 2500000;
          maxPerfBat =
            if cfg.aggressivePowerSave.enable
            then 20
            else 30;
          minPerfBat =
            if cfg.aggressivePowerSave.enable
            then 5
            else 0;
        in {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_SCALING_MIN_FREQ_ON_AC = 800000;
          CPU_SCALING_MAX_FREQ_ON_AC = 0;
          CPU_SCALING_MIN_FREQ_ON_BAT = 800000;
          CPU_SCALING_MAX_FREQ_ON_BAT = maxFreq;

          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;
          CPU_HWP_DYN_BOOST_ON_AC = 1;
          CPU_HWP_DYN_BOOST_ON_BAT = 0;

          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_BAT = maxPerfBat;
          CPU_MIN_PERF_ON_BAT = minPerfBat;

          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "low-power";

          SCHED_POWERSAVE_ON_BAT = 1;
          RUNTIME_PM_ON_AC = "auto";
          RUNTIME_PM_ON_BAT = "auto";
          RUNTIME_PM_DRIVER_PM_ON_BAT = "auto";
          RUNTIME_PM_DRIVER_PM_ALL = 1;

          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "on";

          SATA_LINKPWR_ON_AC = "max_performance";
          SATA_LINKPWR_ON_BAT = "min_power";

          AHCI_RUNTIME_PM_ON_AC = "on";
          AHCI_RUNTIME_PM_ON_BAT = "auto";

          PCIE_ASPM_ON_AC = "default";
          PCIE_ASPM_ON_BAT = "powersupersave";

          USB_AUTOSUSPEND = 1;
          USB_EXCLUDE_AUDIO = 1;
          USB_EXCLUDE_BTUSB = 0;

          START_CHARGE_THRESH_BAT0 = 75;
          STOP_CHARGE_THRESH_BAT0 = 85;

          DEVICES_TO_DISABLE_ON_SHUTDOWN = "bluetooth";
          DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth";
          DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";
          RUNTIME_PM_ON_BAT_EXCLUDE = "0:20:0 00:1f.0";
        };
      };

      systemd.services.battery-optimization = {
        description = "Apply aggressive battery optimizations";
        after = ["tlp.service"];
        before = ["display-manager.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script =
          ''
            echo 1 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null || true
            echo 1 > /sys/module/iwlwifi/parameters/power_save 2>/dev/null || true
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
              echo 800000 > "$cpu" 2>/dev/null || true
            done
            for dev in /sys/bus/pci/devices/*/power/control; do
              echo auto > "$dev" 2>/dev/null || true
            done
            echo auto > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null || true
            echo 3000 > /sys/bus/pci/devices/0000:01:00.0/power/autosuspend_delay_ms 2>/dev/null || true
            echo 0 > /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
            echo Y > /sys/module/printk/parameters/console_suspend 2>/dev/null || true
          ''
          + lib.optionalString cfg.teoIdleGovernor.enable ''
            echo teo > /sys/devices/system/cpu/cpuidle/current_governor 2>/dev/null || true
          '';
      };

      systemd.services.tune-cpu-battery = {
        description = "Tune CPU for battery on boot";
        after = ["battery-optimization.service"];
        before = ["display-manager.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script =
          ''
            ${lib.optionalString cfg.aggressivePowerSave.enable ''
              for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
                echo ${toString cfg.aggressivePowerSave.maxCpuFreqBat} > "$cpu" 2>/dev/null || true
              done
            ''}
            if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
              (cat /sys/class/power_supply/AC0/online 2>/dev/null || cat /sys/class/power_supply/AC/online 2>/dev/null) | grep -q "1" && \
                echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo || \
                echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
            fi
          ''
          + lib.optionalString cfg.coreParking.enable ''
            AC_STATUS=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || cat /sys/class/power_supply/AC/online 2>/dev/null || echo "1")
            if [ "$AC_STATUS" != "1" ]; then
              ${lib.concatMapStringsSep "\n" (cpu: "echo 0 > /sys/devices/system/cpu/cpu${toString cpu}/online 2>/dev/null || true") cfg.coreParking.parkEcoreList}
            fi
          '';
      };

      systemd.paths.ac-monitor = {
        description = "Monitor AC adapter status";
        wantedBy = ["multi-user.target"];
        pathConfig = {
          PathModified = "/sys/class/power_supply/AC0/online";
          Unit = "ac-power-switch.service";
        };
      };

      systemd.services.ac-power-switch = {
        description = "Switch power profiles on AC status change";
        serviceConfig = {
          Type = "oneshot";
        };
        script =
          ''
            SLEEP=2
            sleep $SLEEP
            AC_STATUS=$(cat /sys/class/power_supply/AC0/online 2>/dev/null || cat /sys/class/power_supply/AC/online 2>/dev/null || echo "1")
            if [ "$AC_STATUS" = "1" ]; then
              for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
                cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq > "$cpu" 2>/dev/null || true
              done
              echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
              echo performance > /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || true
              ${lib.optionalString cfg.coreParking.enable ''
                ${lib.concatMapStringsSep "\n" (cpu: "echo 1 > /sys/devices/system/cpu/cpu${toString cpu}/online 2>/dev/null || true") cfg.coreParking.parkEcoreList}
              ''}
            else
              ${lib.optionalString cfg.aggressivePowerSave.enable ''
                for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
                  echo ${toString cfg.aggressivePowerSave.maxCpuFreqBat} > "$cpu" 2>/dev/null || true
                done
              ''}
              echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
              echo power > /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || true
              ${lib.optionalString cfg.coreParking.enable ''
                ${lib.concatMapStringsSep "\n" (cpu: "echo 0 > /sys/devices/system/cpu/cpu${toString cpu}/online 2>/dev/null || true") cfg.coreParking.parkEcoreList}
              ''}
            fi
          ''
          + lib.optionalString cfg.teoIdleGovernor.enable ''
            if [ "$AC_STATUS" = "1" ]; then
              echo menu > /sys/devices/system/cpu/cpuidle/current_governor 2>/dev/null || true
            else
              echo teo > /sys/devices/system/cpu/cpuidle/current_governor 2>/dev/null || true
            fi
          '';
      };

      powerManagement.cpuFreqGovernor = lib.mkForce null;
      powerManagement.powertop.enable = true;

      services.thermald.enable = false;
      services.power-profiles-daemon.enable = false;

      services.undervolt = lib.mkIf cfg.undervolt.enable {
        enable = true;
        verbose = true;
        temp = 0;
        coreOffset = cfg.undervolt.voltageOffset;
        uncoreOffset = cfg.undervolt.voltageOffset;
        gpuOffset = cfg.undervolt.voltageOffset;
        analogioOffset = cfg.undervolt.voltageOffset;
      };
    };
}
