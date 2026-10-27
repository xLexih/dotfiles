{pkgs, ...}: {
  networking.hostName = "laptop";
  system.stateVersion = "26.05";

  modules = {
    hardware.cpu.vendor = "intel";
    hardware.kernel.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
    desktop.hyprland.enable = true;
    services.ssh.enable = true;
    performance = {
      enable = true;
      swap = "zswap";
      buildThreads = 28; # of 32
    };
    theme.default = "hexagon";
  };
}
