{ pkgs, inputs, ... }:
{
  imports = [
    ./adb
    ./ani-cli
    ./codium
    ./docker
    ./firefox
    ./hyprland
    ./opencode
    ./kilo
    ./free-models
    ./kubernetes
    ./lutris
    ./media
    ./minecraft
    ./obs
    ./ollama
    ./office
    ./quickshell
    ./rustdesk
    ./sunshine
    ./spotify
    ./notes
    ./drawing
    ./networking-tools
    ./virtual-machine
    ./waydroid
  ];
  programs.nix-index-database.comma.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };
  services.flatpak.enable = true;
  environment.systemPackages = with pkgs; [
    alejandra
    direnv
    nix-tree
    nil
    nixd
    fzf
    thunar
    tree
    fastfetch
  ];
  programs.nix-ld.enable = true;
}
