{settings, pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.${settings.kernal};

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.editor = true;
    initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];

    supportedFilesystems = ["ntfs"];

    loader.timeout = 0;
  };
}
