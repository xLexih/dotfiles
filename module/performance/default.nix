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
      "vm.swappiness" = 10; # prefer RAM over swap
      "kernel.nmi_watchdog" = 0; # save some overhead
      "net.core.default_qdisc" = "fq_codel"; # low-latency packet scheduling
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    boot.initrd.checkJournalingFS = false;
    boot.consoleLogLevel = 3;

    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.services.systemd-networkd-wait-online.enable = false;
    systemd.settings.Manager = {
      DefaultTimeoutStartSec = "10s";
      DefaultTimeoutStopSec = "10s";
    };

    services.syslogd.enable = false;
  };
}
