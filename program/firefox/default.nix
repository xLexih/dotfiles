# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/programs/firefox.nix
# https://gitlab.com/scientiac/tesseract.home.manager/-/blob/main/apps/graphical/firefox/default.nix#L9
{ config, pkgs, lib, ... }:
{
  options.firefox.username = lib.mkOption {
    type = lib.types.string;
    default = "lex";
  };
  # programs.firefox = {
  #   enable = true;
  #   package = pkgs.wrapFirefox pkgs.firefox-beta-bin-unwrapped {};
    
  #   policies = {};
  #   preferences = {}; 
  #   preferencesStatus = "locked";
  #   profiles = {
  #     default = {
  #       id = 0;
  #       name = config.firefox.username; # want this one to be a variable
  #     };
  #   };
  # };
}