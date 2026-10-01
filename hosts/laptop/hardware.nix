{
  config,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
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
    supportedFilesystems = ["ntfs"];
    kernelModules = [
      "kvm_intel"
      "yt6801" # Motorcomm ethernet
      # Fails its compatibility check on this chassis and unloads. The lightbar
      # LED (ite_8291_lb, from tuxedo-drivers below) loads by device ID, and
      # hid-send writes to /dev/hidraw directly, so neither needs it.
      # "tuxedo-keyboard"
    ];
    blacklistedKernelModules = ["ite_8291"];
    extraModulePackages = with config.boot.kernelPackages; [
      acpi_call
      tuxedo-drivers
      yt6801
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/ROOT";
      fsType = "ext4";
      options = ["noatime"];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6B36-A50E";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077" "noatime"];
    };
    "/data" = {
      device = "/dev/disk/by-label/DATA";
      fsType = "ext4";
      options = ["noauto" "comment=systemd.automount" "x-systemd.automount"];
    };
  };

  modules.hardware.graphics = {
    enable = true;
    intel.enable = true;
    nvidia = {
      enable = true;
      hybrid = {
        enable = true;
        igpuVendor = "intel";
        igpuBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
        # The NVIDIA GPU powers off unless a game or `nvidia-offload` uses it.
        offloadOnly = true;
      };
    };
    vaapi = {
      enable = true;
      firefox.enable = true;
    };
  };
}
