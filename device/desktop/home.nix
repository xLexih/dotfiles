{ config, pkgs, username, lib, ... }:
{
  imports = [
    ../../user/${username}/home.nix
    ../../home/program/hyprland/home.nix # Set's up hyprland
  ];
  home.packages = with pkgs; [
    firefox
    vesktop
  ];
}
