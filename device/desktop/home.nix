{ config, pkgs, username, lib, ... }:
{
  imports = [
    ../../user/${username}/home.nix
    ../../home/program/hyprland/home.nix # Set's up hyprland
  ];
  home.packages = with pkgs; [
    hello # testing package
    firefox # browser duuh
    vesktop # Discord, but better!
    alacritty # My preferred terminal 
    vscodium.fhs # Editorrrr
  ];
}
