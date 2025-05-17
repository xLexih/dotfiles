{ config, pkgs, username, lib, ... }:

let
  user = import ./user/${username}/home.nix { inherit config pkgs username lib; };
in
lib.recursiveUpdate
  {
    home.packages = with pkgs; [
      wl-clipboard
      kitty
      hyprpaper
      rofi-wayland
      waybar
      gnome-icon-theme
    ];
  }
  user
