{ config, pkgs, ... }:

{
  imports = [
    ./boot.nix
  ];

  hardware.pulseaudio.enable = true;
  nixpkgs.config.pulseaudio = true;
  services.openssh.enable = true;
  users.extraUsers.lex = {
    isNormalUser = true;
    home = "/home/lex";
    extraGroups = [ "wheel" ];
    uid = 1000;
  };
}
