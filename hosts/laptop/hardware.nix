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
    ];
    blacklistedKernelModules = [
      "ite_8291"
      # The board's WMI GUIDs pull in these tuxedo-drivers modules, which fail
      # their compatibility check on this chassis and unload again (four
      # tuxedo_keyboard inits per boot). The lightbar driver (ite_8291_lb)
      # matches by USB ID and hid-send writes /dev/hidraw, so neither needs them.
      "clevo_acpi"
      "clevo_wmi"
      "uniwill_wmi"
      "tuxedo_keyboard"
      # ASUS platform drivers, loaded without an ASUS device.
      "asus_wmi"
      "asus_nb_wmi"
      "eeepc_wmi"
      # i915 drives this GPU; xe probes it too and stays loaded unused.
      "xe"
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      acpi_call
      tuxedo-drivers
      yt6801
    ];
  };

  # nixos-hardware loads i915 in the initrd for an early full-resolution
  # console; the initrd then waits ~0.5 s for it. With a quiet boot nothing
  # shows that early, so it loads in parallel after the switch to the root fs.
  hardware.intelgpu.loadInInitrd = false;

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

  # 40 GiB at the end of the disk: larger than RAM, so hibernation fits.
  swapDevices = [{device = "/dev/disk/by-label/SWAP";}];
  boot.resumeDevice = "/dev/disk/by-label/SWAP";

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
