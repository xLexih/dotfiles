{ config, pkgs,lib, ... }:

{
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.systemd-networkd-wait-online.enable = false;
  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = [];

  systemd.services.NetworkManager = {
    after = lib.mkForce [ "dbus.service" "systemd-resolved.service" ];
    wants = lib.mkForce [ "dbus.service" ];
    serviceConfig = {
      TimeoutStartSec = "5s";
    };
  };

  systemd.services.nftables = {
    wants = [ "network.target" ];
    after = [ "network.target" ];
    before = lib.mkForce [ ];
  };

  networking = {
    useDHCP = lib.mkDefault false; # Let NetworkManager handle DHCP
    networkmanager = {
      settings.connection."ipv6.ip6-privacy" = 2;
      dhcp = "internal";
    };
  };
  services.resolved.enable = true;
}