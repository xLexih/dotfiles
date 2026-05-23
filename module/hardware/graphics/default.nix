{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.graphics;
in {
  imports = [
    ./amd.nix
    ./intel.nix
    ./nvidia.nix
    ./vaapi.nix
  ];

  options.modules.hardware.graphics = {
    enable = lib.mkEnableOption "graphics stack";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [vulkan-loader];
      extraPackages32 = with pkgs; [vulkan-loader];
    };
  };
}
