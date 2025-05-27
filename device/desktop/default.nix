# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, settings, ... }:

{  
  imports =
    [
      ./boot.nix
      # ../../module/system.nix
      ../../program/hyprland # Set's up hyprland
    ];

  graphicsModule = {
    amd.enable = true;
    nvidia = {
      enable = true;
      hybrid = {
        enable = true;
        igpu = {
          vendor = "amd";
          port = "PCI:10:0:0"; #"pci@0000:10:00.0";
        };
        dgpu.port = "PCI:1:0:0";#"pci@0000:01:00.0";
      };
    };
  };

  networking.hostName = "desktop"; # Define your hostname.

  networking.networkmanager.enable = true;

  system.stateVersion = settings.stateVersion;
}
