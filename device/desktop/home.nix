{ config, pkgs, username, lib, self, ... }: {
  imports = /*map (path: self + path)*/ [
    ../../user/lex/home.nix
    ../../home/program/hyprland/home.nix # Set's up hyprland
    ../../home/program/firefox/home.nix # Set's up firefox
    ../../home/program/lutris/home.nix # Set's up firefox

  ];
  home.packages = with pkgs; [
    hello # testing package
    vesktop # Discord, but better!
    alacritty # My preferred terminal
    vscodium.fhs # Editorrrr
  ];
}
