{modulesPath, ...}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.timeout = 0;
  boot.supportedFilesystems = [
    "btrfs"
    "ntfs"
  ];
  boot.kernelModules = [
    "kvm_amd" # AMD virtualization
  ];
}
