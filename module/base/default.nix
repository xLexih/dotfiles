{pkgs, ...}: {
  time.timeZone = "Europe/Ljubljana";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_COLLATE = "C"; # dotfiles-first sorting in ls
    };
  };

  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  users.defaultUserShell = pkgs.bash;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    unzip
    zip
    ripgrep # grep alternative, rg
    fd # find alternative
    eza # ls alternative
    bat # cat alternative
    btop # resource monitor
    file
    killall
    pciutils # lspci
    upower
    usbutils # lsusb
    xdg-ninja
  ];

  programs.bash = {
    completion.enable = true;
  };

  services.fwupd.enable = true; # firmware updates

  services.dbus.packages = with pkgs; [
    gcr
    gnome-keyring
  ];

  services.udev.packages = with pkgs; [
    gnome-settings-daemon
  ];

  hardware.steam-hardware.enable = true;

  services.flatpak.enable = true;

  security.sudo.wheelNeedsPassword = false;
}
