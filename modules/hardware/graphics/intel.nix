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
    boot.kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
    ];

    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-vaapi-driver
      libvdpau-va-gl
    ];
    environment.variables.LIBVA_DRIVER_NAME = "iHD";
  };
}
