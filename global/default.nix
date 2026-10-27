# System defaults shared by every host.
{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.hjem.nixosModules.default
    inputs.nix-index-database.nixosModules.nix-index
    inputs.spicetify-nix.nixosModules.spicetify
  ];

  time.timeZone = "Europe/Ljubljana";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings.LC_COLLATE = "C"; # dotfiles first in ls
  };

  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  users.defaultUserShell = pkgs.bash;
  programs.bash.completion.enable = true;
  # One password covers 15 minutes of sudo (a whole `nh os switch`); typing
  # shows stars.
  security.sudo.extraConfig = ''
    Defaults pwfeedback
    Defaults timestamp_timeout=15
  '';

  # Managed home files replace whatever is in the way on activation.
  hjem.clobberByDefault = true;

  # Lets qmllint/qmlls resolve Quickshell imports in ~/.config/quickshell.
  dotfiles.vars."qml.importPaths" = lib.concatMapStringsSep ", " (pkg: "${pkg}/lib/qt-6/qml") [
    pkgs.quickshell
    pkgs.qt6.qt5compat
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtbase
  ];

  documentation.man.cache.enable = true;
  documentation.dev.enable = true;

  environment.systemPackages = with pkgs; [
    bat
    btop
    curl
    eza
    fd
    file
    git
    killall
    man-pages
    man-pages-posix
    pciutils
    ripgrep
    stdman
    unzip
    upower
    usbutils
    wget
    xdg-ninja
    zip
  ];

  services.fwupd.enable = true;
  services.flatpak.enable = true;
  # gnome-keyring's own services come from services.gnome.gnome-keyring.
  services.dbus.packages = [pkgs.gcr_4];
  services.udev.packages = [pkgs.gnome-settings-daemon];
  hardware.steam-hardware.enable = true;

  # Caps on disk use: the journal had grown to 1.7 GB and crash dumps (mostly
  # omp's headless Chrome) to 2.1 GB.
  services.journald.settings.Journal.SystemMaxUse = "500M";
  systemd.coredump.settings.Coredump.MaxUse = "500M";
}
