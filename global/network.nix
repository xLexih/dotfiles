{
  boot.kernelModules = ["tun"];

  networking = {
    nftables.enable = true;
    firewall = {
      enable = true;
      allowPing = true;
    };
    networkmanager = {
      enable = true;
      dhcp = "internal";
      wifi.powersave = false;
      wifi.macAddress = "random";
      connectionConfig = {
        "connection.mdns" = 2;
        "ipv6.ip6-privacy" = 2;
      };
    };
  };

  services.resolved.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General = {
      ControllerMode = "dual";
      Experimental = true;
    };
  };
  services.blueman.enable = true;
}
