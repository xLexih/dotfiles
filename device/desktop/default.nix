# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, settings, ... }:

{  
  imports =
    [
      ./boot.nix
      ../../program/hyprland # Set's up hyprland
    ];
#  graphicsModule = {
 #   amd.enable = false;
#    nvidia = {
#      enable = true;
      # This option is only for laptops.. If you have dual gpus (igpu)
      # DISABLE IT FROM THE BIOSSSS HOW DARE YOU EVEN CONSIDER MAKING IT WORKKK
#      hybrid = {
#        enable = false; # I belive i can't do it on my main machine? might be a laptop only thing. (enables prime)
#        igpu = {
#          vendor = "amd";
          # [AMD/ATI] Raael  | 10:00.0 VGA
#          port = "PCI:16@0:0:0"; #"pci@0000:10:00.0";
#        };
        # GeForce RTX 3070 Ti  |  01:00.0 
#        dgpu.port = "PCI:1@0:0:0"; #"pci@0000:01:00.0";
#      };
#    };
 # };
  # Forgor what dis is



  # Load nvidia driver for Xorg and Wayland

  services.xserver.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  # services.xserver.displayManager.gdm.wayland = true;

  hardware.nvidia = {
#     # Modesetting is required.
    modesetting.enable = true;
#     # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
#     powerManagement.enable = false;
#     # Fine-grained power management. Turns off GPU when not in use.
#     # Experimental and only works on modern Nvidia GPUs (Turing or newer).
#     powerManagement.finegrained = false;
#     # Use the NVidia open source kernel module (not to be confused with the
#     # independent third-party "nouveau" open source driver).
#     # Support is limited to the Turing and later architectures. Full list of
#     # supported GPUs is at:
#     # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
#     # Only available from driver 515.43.04+
#     # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;
#     # Enable the Nvidia settings menu,
#     # accessible via `nvidia-settings`.
#     nvidiaSettings = true;
#     # Added for better Wayland compatibility
#     forceFullCompositionPipeline = true;
#     # Optionally, you may need to select the appropriate driver version for your specific GPU.
#     #package = config.boot.kernelPackages.nvidiaPackages.stable;
#     package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
#  version = "575.51.02";
#       sha256_64bit = "sha256-XZ0N8ISmoAC8p28DrGHk/YN1rJsInJ2dZNL8O+Tuaa0=";
#       sha256_aarch64 = "sha256-NNeQU9sPfH1sq3d5RUq1MWT6+7mTo1SpVfzabYSVMVI=";
#       openSha256 = "sha256-NQg+QDm9Gt+5bapbUO96UFsPnz1hG1dtEwT/g/vKHkw=";
#       settingsSha256 = "sha256-6n9mVkEL39wJj5FB1HBml7TTJhNAhS/j5hqpNGFQE4w=";
#       persistencedSha256 = "sha256-dgmco+clEIY8bedxHC4wp+fH5JavTzyI1BI8BxoeJJI=";    };
  };

  # Environment variables for Wayland/Nvidia compatibility
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # Kernel parameters for Nvidia and display handling
  boot.kernelParams = [ 
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia-drm.modeset=1"
"module_blacklist=amdgpu" # big bad bad bad bad bad bad bad bad badbad badb adbadbad badb adb adbabd abdbadbadad
      ];



  programs.dconf.enable = true;
  environment.sessionVariables = {
    ADW_DISABLE_PORTAL = "1";
  };
  environment.etc."xdg/gtk-4.0/assets".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/assets";
  environment.etc."xdg/gtk-4.0/gtk.css".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk.css";
  environment.etc."xdg/gtk-4.0/gtk-dark.css".source = "${pkgs.nordic}/share/themes/Nordic/gtk-4.0/gtk-dark.css";
  environment.systemPackages = with pkgs; [
    nordic
    gtk4
      hyprcursor
      nwg-look
      glib
      flat-remix-gtk
      bibata-cursors
      adwaita-icon-theme
  ];

  networking.hostName = "desktop"; # Define your hostname.

  networking.networkmanager.enable = true;

  system.stateVersion = settings.stateVersion;
}
