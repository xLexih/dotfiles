{pkgs, ...}: {
  networking.hostName = "desktop";
  system.stateVersion = "26.05";

  modules = {
    hardware.cpu.vendor = "amd";
    hardware.kernel.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
    desktop.hyprland.enable = true;
    services.ssh.enable = true;
    performance = {
      enable = true;
      buildThreads = 12; # of 16
    };
    theme.default = "hexagon";
  };
}
