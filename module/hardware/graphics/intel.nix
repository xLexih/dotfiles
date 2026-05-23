{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.graphics;
in {
  options.modules.hardware.graphics.intel = {
    enable = lib.mkEnableOption "Intel integrated graphics";
  };

  config = lib.mkIf (cfg.enable && cfg.intel.enable) {
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver # iHD driver
      vpl-gpu-rt # video processing
      intel-vaapi-driver # i965 fallback
      libvdpau-va-gl # VDPAU via VA-API
    ];
    environment.variables.LIBVA_DRIVER_NAME = "iHD";
  };
}
