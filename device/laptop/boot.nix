{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # File sytem
  fileSystems."/" = {
    device = "/dev/disk/by-label/ROOT";
    fsType = "ext4";
    options = [ "noatime" "nodiratime" "discard" ];
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4"; 
    options = [ "noauto" "comment=systemd.automount" "x-systemd.automount" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6B36-A50E";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" "noatime" "nodiratime" ];
  };
  # swapDevices = [{ device = "/dev/disk/by-uuid/f805f37b-0d4f-4186-8c0a-56b2b97f6eeb"; }];
  zramSwap.enable = true;
  zramSwap.algorithm = "lz4";
  # boot.initrd.includeDefaultModules = false;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Boot options
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

