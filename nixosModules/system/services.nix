{ pkgs, ... }: {
  # uncategorized
  services.thermald.enable = true;
  services.fwupd.enable = true;
  services.dbus.packages = [ pkgs.gcr ];
  services.udev.packages = [ pkgs.gnome-settings-daemon ];
  services.geoclue2.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };
  # disable sddm
  services.displayManager.sddm.enable = false;

  # cups [printers]
  services.printing.enable = false;

  # extra firmware
  hardware.enableAllFirmware = true;
  hardware.steam-hardware.enable = true;

}
