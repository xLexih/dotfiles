{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.graphics;
in {
  options.modules.hardware.graphics.enable = lib.mkEnableOption "the graphics stack";

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [pkgs.vulkan-loader];
      extraPackages32 = [pkgs.vulkan-loader];
    };
  };
}
