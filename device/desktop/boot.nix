{ config, lib, pkgs, modulesPath, settings, ... }:


{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  # File system
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a63fe885-b94e-42a2-8330-9ba4f5df57df";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CD0B-0C93";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/73354cf4-f3b2-49b1-9c26-94c925f5c5fa"; }];
  # Boot options
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.kernelModules = [ "kvm-amd" ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault settings.system;
  
  # hardware.opengl.enable = true;
  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true;
  # };

  # hardware.nvidia = {
  # open = true;
  #       modesetting.enable = true;
  #       nvidiaSettings = true;
  #       package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
