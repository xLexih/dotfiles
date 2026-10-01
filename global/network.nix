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
      connectionConfig."ipv6.ip6-privacy" = 2;
    };
  };

  # Avahi answers and resolves .local names (Sunshine needs it). A second
  # mDNS stack in resolved made lookups unreliable.
  services.resolved = {
    enable = true;
    settings.Resolve.MulticastDNS = false;
  };

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
