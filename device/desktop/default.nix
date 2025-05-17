# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
      ./boot.nix
    ];
  
  networking.hostName = "desktop"; # Define your hostname.
  
  services.xserver.videoDrivers = [ "nvidia" ];
  programs.xwayland.enable = true;  
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
  };

  
  networking.networkmanager.enable = true;
  users.users.lex = {
    isNormalUser = true;
    description = "lex";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
  environment.systemPackages = with pkgs; [
    
    git  
 
    wl-clipboard
    kitty
    hyprpaper
    rofi-wayland
    waybar
    gnome-icon-theme
  ];
  system.stateVersion = "24.11";
}
