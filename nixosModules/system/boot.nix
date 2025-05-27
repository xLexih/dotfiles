{...}: {
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.editor = true;
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];

    supportedFilesystems = ["ntfs"];

    loader.timeout = 0;
  };
}