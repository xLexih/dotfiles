# Responsiveness and boot tuning. Memory, writeback, THP and I/O settings
# follow CachyOS's defaults (CachyOS-Settings).
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.performance;
in {
  options.modules.performance.enable = lib.mkEnableOption "host performance tuning";

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=auto"
      # zram already compresses swapped pages; zswap in front of it would
      # compress them a second time.
      "zswap.enabled=0"
    ];
    boot.consoleLogLevel = 3;
    boot.initrd.compressor = "zstd";
    boot.initrd.checkJournalingFS = false;

    # Hardware watchdogs only reboot a hung machine and cause periodic wakeups.
    boot.blacklistedKernelModules = ["iTCO_wdt" "sp5100_tco" "wdat_wdt"];

    # Compressed swap in RAM, sized like CachyOS: up to the size of RAM, used
    # before the disk swap partition.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 100;
      priority = 100;
    };

    boot.kernel.sysctl = {
      # Swapping to zram is cheap, so idle pages go there before disk cache
      # is dropped (CachyOS sets 150 once zram is active).
      "vm.swappiness" = 150;
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
    systemd.services.nscd.wantedBy = lib.mkForce [];
    systemd.services.wpa_supplicant.wantedBy = lib.mkForce [];
    systemd.services.fwupd.wantedBy = lib.mkForce [];
    systemd.sockets.fwupd.wantedBy = lib.mkForce [];
    systemd.services.libvirtd.wantedBy =
      lib.mkIf config.modules.software.virtual-machine.enable (lib.mkForce []);
    systemd.services.waydroid-container.wantedBy =
      lib.mkIf config.modules.software.waydroid.enable (lib.mkForce []);
    systemd.services.spice-vdagentd.wantedBy =
      lib.mkIf config.modules.software.virtual-machine.enable (lib.mkForce []);
  };
}
