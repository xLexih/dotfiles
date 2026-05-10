{lib, ...}: {
  imports = [
    ./bluetooth.nix
    ./mdns.nix
  ];
  nix.settings.substituters = [
    "https://aseipp-nix-cache.global.ssl.fastly.net" 
    "https://nix-community.cachix.org"
    "https://cuda-maintainers.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
  ];
  networking = {
    useDHCP = lib.mkDefault true;
    nftables.enable = true;
    networkmanager = {
      enable = true;
      wifi = {
        powersave = false; #
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
