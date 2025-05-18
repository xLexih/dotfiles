{ config, pkgs, ... }:

{
  programs.xwayland.enable = true;  
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
  };
}
