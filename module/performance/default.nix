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
    ];

    boot.initrd.compressor = "zstd";

    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
      "kernel.nmi_watchdog" = 0;
      "net.core.default_qdisc" = "fq_codel";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    boot.initrd.checkJournalingFS = false;
    boot.consoleLogLevel = 3;

    zramSwap = {
      enable = true;
      algorithm = "lz4";
    };

    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.systemd-networkd-wait-online.enable = false;
    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "10s";
      DefaultTimeoutStopSec = "10s";
    };

    services.syslogd.enable = false;

    # Redundant/on-demand services
    services.avahi.enable = lib.mkForce false;
    services.openssh.enable = lib.mkForce false;
    systemd.services.nscd.wantedBy = lib.mkForce [];
    systemd.services.wpa_supplicant.wantedBy = lib.mkForce [];
    systemd.services.fwupd.wantedBy = lib.mkForce [];
    systemd.sockets.fwupd.wantedBy = lib.mkForce [];

    # Socket-activated / manual-start only
    systemd.services.libvirtd.wantedBy =
      lib.mkIf config.modules.software.virtual-machine.enable (lib.mkForce []);
    systemd.services.waydroid-container.wantedBy =
      lib.mkIf config.modules.software.waydroid.enable (lib.mkForce []);
    systemd.services.spice-vdagentd.wantedBy =
      lib.mkIf config.modules.software.virtual-machine.enable (lib.mkForce []);
  };
}
