{...}: {
  imports = [
    ./boot/default.nix
    ./hardware/default.nix
    ./storage/default.nix
  ];

  networking.hostName = "desktop";
  system.stateVersion = "26.05";

  modules.hardware.cpu.vendor = "amd";
  modules.hardware.kernel.package = "xanmod_latest";
  modules.performance.enable = true;
  modules.theme = {
    enable = true;
    name = "hexagon";
  };

  modules.session.hyprland.enable = true;
  modules.session.greetd.enable = true;
}
