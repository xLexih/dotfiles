{...}: {
  imports = [
    ./boot/default.nix
    ./hardware/default.nix
    ./storage/default.nix
  ];

  networking.hostName = "desktop";
  system.stateVersion = "25.11";

  modules.hardware.cpu.vendor = "amd";
  modules.hardware.kernel.package = "xanmod_latest";
  modules.performance.enable = true;
  modules.theme.hexagon.enable = true;

  modules.session.hyprland.enable = true;
  modules.session.greetd.enable = true;
}
