{pkgs, ...}: {
  # uncategorized
  services.dbus.packages = [pkgs.gcr pkgs.gnome-keyring];
  services.udev.packages = [pkgs.gnome-settings-daemon];
  
  services.fwupd.enable = true;
  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };
  # cups [printers]
  services.printing.enable = false;

  # extra firmware
  hardware.enableAllFirmware = true;
  hardware.steam-hardware.enable = true;
}
