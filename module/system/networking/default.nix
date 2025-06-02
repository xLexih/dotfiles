{lib, ...}: {
  imports = [./bluetooth.nix];

  networking = {
    useDHCP = lib.mkDefault true;
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
      allowedTCPPortRanges = [];
      allowedUDPPortRanges = [];
    };
  };
}
