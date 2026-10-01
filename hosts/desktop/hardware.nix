{
  config,
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
    kernelModules = [
      "kvm_amd"
      "nct6687" # fan and voltage sensors of the board's Nuvoton Super I/O
    ];
    extraModulePackages = [config.boot.kernelPackages.nct6687d];
    # On ethernet only; Bluetooth on the same card has its own driver.
    blacklistedKernelModules = ["mt7921e"];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/a63fe885-b94e-42a2-8330-9ba4f5df57df";
      fsType = "ext4";
      options = ["noatime"];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/CD0B-0C93";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077" "noatime"];
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
    # Both monitors are on the NVIDIA card, which renders the desktop; the
    # iGPU only serves compute (ROCm).
    nvidia.enable = true;
    vaapi = {
      enable = true;
      firefox.enable = true;
    };
  };
}
