{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./boot/default.nix
    ./hardware/default.nix
    ./storage/default.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  networking.hostName = "laptop";
  system.stateVersion = "26.05";

  modules.hardware.cpu.vendor = "intel";
  modules.hardware.kernel.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
  modules.performance.enable = true;
  modules.theme = {
    enable = true;
    name = "hexagon";
  };
  modules.session.hyprland.enable = true;
}
