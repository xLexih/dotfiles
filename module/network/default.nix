{...}: {
  networking.nftables.enable = true; # modern firewall backend

  networking.networkmanager = {
    enable = true;
    wifi.powersave = false; # disable wifi powersave
    wifi.macAddress = "random"; # privacy
    connectionConfig."connection.mdns" = 2;
    connectionConfig."ipv6.ip6-privacy" = 2; # temporary addresses
    dhcp = "internal"; # faster than dhclient
  };

  networking.firewall = {
    enable = true;
    allowPing = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.resolved.enable = true; # modern dns resolution

  services.avahi = {
    enable = true;
    nssmdns4 = true; # .local hostname resolution
    openFirewall = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # saves power
    settings.General.ControllerMode = "dual"; # br/edr + le
    settings.General.Experimental = true;
  };
  services.blueman.enable = true; # bluetooth gui
}
