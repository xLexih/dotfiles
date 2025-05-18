# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, username, system, ... }:

{
  imports =
    [
      ./boot.nix
      ../../module/system.nix
      ../../home/program/hyprland # Set's up hyprland
    ];
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "desktop"; # Define your hostname.
  
  services.xserver.videoDrivers = [ "nvidia" ];
  
  networking.networkmanager.enable = true;

  system.stateVersion = "24.11";
}
