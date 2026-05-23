{...}: {
  imports = [
    ./boot/default.nix
    ./hardware/default.nix
    ./storage/default.nix
  ];

  networking.hostName = "laptop";
  system.stateVersion = "25.11";

  modules.hardware.cpu.vendor = "intel";
  modules.hardware.kernel.package = "xanmod_latest";
  modules.performance.enable = true;
  modules.session.hyprland.enable = true;
}
