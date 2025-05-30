{ ... }: {
  imports = [ ./bluetooth.nix ];

  networking = {
    nftables.enable = true;
    networkmanager = {
      enable = true;
      wifi = {
        powersave = false;
        macAddress = "random";
      };
    };

    firewall = {
      enable = true;
      allowedTCPPortRanges = [ ];
      allowedUDPPortRanges = [ ];
    };
  };
}
