# Responsiveness and boot tuning. Memory, writeback, THP and I/O settings
# follow CachyOS's defaults (CachyOS-Settings).
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.performance;
  zram = cfg.swap == "zram";
in {
  options.modules.performance = {
    enable = lib.mkEnableOption "host performance tuning";
    swap = lib.mkOption {
      type = lib.types.enum ["zram" "zswap"];
      default = "zram";
      description = ''
        "zram": compressed swap in RAM only, as CachyOS does. "zswap": a
        compressed RAM cache in front of the host's `swapDevices`, which
        moves cold pages on to disk (and allows hibernation).
      '';
    };
    buildThreads = lib.mkOption {
      type = lib.types.ints.positive;
      example = 28;
      description = ''
        CPU threads all Nix builds together may use (a CPU quota on
        nix-daemon). The host's remaining threads stay free for the desktop.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams =
      [
        "quiet"
        "loglevel=3"
        "rd.systemd.show_status=auto"
        # Swap comes only from zram or `swapDevices`; GPT auto-discovery
        # would activate any undeclared swap partition behind them.
        "systemd.gpt_auto=0"
      ]
      # The kernel enables zswap (zstd, shrinker on) by default; in front of
      # zram it would compress pages a second time.
      ++ lib.optional zram "zswap.enabled=0";
    boot.consoleLogLevel = 3;
    boot.initrd.compressor = "zstd";
    boot.initrd.checkJournalingFS = false;

    # Hardware watchdogs only reboot a hung machine and cause periodic wakeups.
    boot.blacklistedKernelModules = ["iTCO_wdt" "sp5100_tco" "wdat_wdt"];

    # Up to the size of RAM, like CachyOS.
    zramSwap = lib.mkIf zram {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
      priority = 100;
    };

    # systemd-oomd runs by default but watches no cgroup, so a runaway process
    # can fill RAM and all swap before the kernel OOM killer steps in. As on
    # Fedora: once swap is 90% used, kill the cgroup holding the most swap, and
    # kill user units that stay under heavy memory pressure (80% for 30 s).
    systemd.oomd.enableUserSlices = true;
    systemd.slices."-".sliceConfig.ManagedOOMSwap = "kill";

    # Local builds (the CachyOS kernel has no binary cache) yield to the
    # desktop: batch CPU and idle I/O scheduling, at most buildThreads CPU
    # threads in total, and their compilers are the kernel OOM killer's first
    # pick instead of the browser or the session. Evaluation runs in the nix
    # client, outside the quota.
    nix.daemonCPUSchedPolicy = "batch";
    nix.daemonIOSchedClass = "idle";
    nix.settings.cores = cfg.buildThreads;
    systemd.services.nix-daemon.serviceConfig = {
      OOMScoreAdjust = 500;
      CPUQuota = "${toString (cfg.buildThreads * 100)}%";
    };

    boot.kernel.sysctl = {
      # Swapping to zram is cheap, so idle pages go there before disk cache
      # is dropped (CachyOS sets 150 once zram is active). Disk-backed swap
      # behind zswap gets the kernel's even split.
      "vm.swappiness" =
        if zram
        then 150
        else 100;
      "vm.page-cluster" = 0;
      "vm.vfs_cache_pressure" = 50;
      # Flush dirty pages early and in small amounts instead of stalling on
      # gigabytes at once.
      "vm.dirty_bytes" = 268435456;
      "vm.dirty_background_bytes" = 67108864;
      "vm.dirty_writeback_centisecs" = lib.mkDefault 1500;
      "kernel.nmi_watchdog" = 0;
      "net.core.netdev_max_backlog" = 4096;
      "net.core.default_qdisc" = "fq_codel";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    systemd.tmpfiles.rules = [
      "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
      "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
    ];

    # kyber keeps reads responsive while large writes are queued.
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    '';

    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.systemd-networkd-wait-online.enable = false;
    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "10s";
      DefaultTimeoutStopSec = "10s";
    };

    services.syslogd.enable = false;

    # Started on demand instead of at boot.
    services.avahi.enable =
      lib.mkIf (!config.modules.software.sunshine.enable) (lib.mkForce false);
    systemd.services.wpa_supplicant.wantedBy = lib.mkForce [];
    systemd.services.fwupd.wantedBy = lib.mkForce [];
    systemd.sockets.fwupd.wantedBy = lib.mkForce [];
    systemd.services.libvirtd.wantedBy =
      lib.mkIf config.modules.software.virtual-machine.enable (lib.mkForce []);
    systemd.services.waydroid-container.wantedBy =
      lib.mkIf config.modules.software.waydroid.enable (lib.mkForce []);
  };
}
