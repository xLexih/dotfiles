{
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 0; # hold space for the menu
    };
    supportedFilesystems = ["btrfs" "ntfs"];
    kernelModules = ["kvm_amd"];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/a63fe885-b94e-42a2-8330-9ba4f5df57df";
      fsType = "ext4";
      options = ["noatime" "nodiratime" "discard"];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/CD0B-0C93";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077" "noatime" "nodiratime"];
    };
    "/data" = {
      device = "/dev/disk/by-uuid/e7f8b63d-b2b2-4cbe-a825-6fde9c6d7afb";
      fsType = "btrfs";
      options = ["noauto" "comment=systemd.automount" "x-systemd.automount"];
    };
  };

  modules.hardware.graphics = {
    enable = true;
    amd.enable = true;
    nvidia = {
      enable = true;
      hybrid = {
        enable = true;
        igpuVendor = "amd";
        igpuBusId = "PCI:10:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    vaapi = {
      enable = true;
      firefox.enable = true;
    };
  };
}
