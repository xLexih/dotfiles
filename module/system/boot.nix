{
  settings,
  pkgs,
  lib,
  ...
}: {
  boot = {
    kernelPackages = pkgs."linuxPackages_${settings.kernel_name}";

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.editor = true;
    supportedFilesystems = ["ntfs"];

    loader.timeout = 0;
  };
}
