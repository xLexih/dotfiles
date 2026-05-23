{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.netclient;
in {
  options.modules.software.netclient = {
    enable = lib.mkEnableOption "Netclient mesh VPN daemon";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.netclient];

    networking.firewall.trustedInterfaces = ["netmaker"];
    networking.firewall.checkReversePath = "loose";

    systemd.services.netclient = {
      description = "Netclient Daemon";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        ExecStart = "${pkgs.netclient}/bin/netclient daemon";
        Restart = "on-failure";
        RestartSec = "5s";
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN";
      };
      path = with pkgs; [wireguard-tools iproute2 iptables];
    };
  };
}
