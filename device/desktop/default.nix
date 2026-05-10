# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  settings,
  lib,
  config,
  ...
}:
{
  imports = [
    ./boot.nix
  ];
  program.app.hyprland.enable = true;
  boot.kernelModules = [
    "kvm-amd"
    "nvidia"
  ];
  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.beta;

  graphicsModule = {
    dgpu = "pci-0000:01:00.0-card";
    igpu = "pci-0000:10:00.0-card";
    amd.enable = false;
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

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.hostName = settings.hostName;
  networking.networkmanager.enable = true;
}
