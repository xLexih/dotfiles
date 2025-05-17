# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
      ./boot.nix
      ./hyprland.nix
    ];
  
  networking.hostName = "desktop"; # Define your hostname.
  
  services.xserver.videoDrivers = [ "nvidia" ];

  
  networking.networkmanager.enable = true;
  users.users.lex = {
    isNormalUser = true;
    description = "lex";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
  environment.systemPackages = with pkgs; [
    git  
  ];
  system.stateVersion = "24.11";
}
