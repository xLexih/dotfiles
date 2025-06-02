{pkgs, ...}: {
  # uncategorized
  services.dbus.packages = [pkgs.gcr];
  services.udev.packages = [pkgs.gnome-settings-daemon];

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
