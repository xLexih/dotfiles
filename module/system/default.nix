{settings, ...}: {
  imports = [
    ./boot.nix
    ./audio.nix
    ./fonts.nix
    ./locales.nix
    ./networking
    ./services.nix
    ./xdg.nix
  ];

  system.stateVersion = settings.stateVersion;
}
