# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
#      ./flake.nix
    ];

  nix.nixPath = [
    "nixos-config=/home/lex/.dotfile"
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];



  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.editor = true;
  hardware = {
    graphics = {
      enable = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  programs.xwayland.enable = true;  
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
  };

  networking.hostName = "desktop"; # Define your hostname.
  networking.networkmanager.enable = true;
  users.users.lex = {
    isNormalUser = true;
    description = "lex";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
  environment.systemPackages = with pkgs; [
    wl-copy
    kitty
    hyprpaper
    rofi-wayland
    waybar
    gnome-icon-theme
  ];
  system.stateVersion = "24.11";
}
