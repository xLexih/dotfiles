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

  graphicsModule = {
 #   amd.enable = false;
    nvidia = {
      enable = true;
      # This option is only for laptops.. If you have dual gpus (igpu)
      # DISABLE IT FROM THE BIOSSSS HOW DARE YOU EVEN CONSIDER MAKING IT WORKKK
#      hybrid = {
#        enable = false; # I belive i can't do it on my main machine? might be a laptop only thing. (enables prime)
#        igpu = {
#          vendor = "amd";
          # [AMD/ATI] Raphael  | 10:00.0 VGA
#          port = "PCI:16@0:0:0"; #"pci@0000:10:00.0";
#        };
        # GeForce RTX 3070 Ti  |  01:00.0 
#        dgpu.port = "PCI:1@0:0:0"; #"pci@0000:01:00.0";
#      };
    };
  };
  # Forgor what dis is
 services.xserver.videoDrivers = [
    "modesetting"  # example for Intel iGPU; use "amdgpu" here instead if your iGPU is AMD
    "nvidia"
  ];
  boot.blacklistedKernelModules = [ "spd5118" ]; # lsmod | grep -e ee1004 -e spd5118
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
