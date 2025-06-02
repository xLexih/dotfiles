# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  settings,
  ...
}: {
  imports = [
    ./boot.nix
    ../../module/program/hyprland # Set's up hyprland
  ];
  boot.kernelModules = ["kvm-amd" "nvidia"];

  graphicsModule = {
    amd.enable = true;
    nvidia = {
      enable = true;
      hybrid = {
        enable = true;
        igpu = {
          vendor = "amd";
          port = "PCI:16@0:0:0"; # [AMD/ATI] Raael      | 10:00.0   pci@0000:10:00.0
        };
        dgpu.port = "PCI:1@0:0:0"; # GeForce RTX 3070 Ti  | 01:00.0   pci@0000:01:00.0
      };
    };
  };

  networking.hostName = settings.hostName; # Define your hostname.

  networking.networkmanager.enable = true;

  system.stateVersion = settings.stateVersion;
}
