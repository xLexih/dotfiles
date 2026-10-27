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
    boot.kernelParams = ["i915.enable_fbc=1"];

    # nixos-hardware's common-gpu-intel (via common-cpu-intel) adds the VA-API
    # drivers and media runtime.
    hardware.graphics.extraPackages = [pkgs.libvdpau-va-gl];
    environment.variables.LIBVA_DRIVER_NAME = "iHD";
  };
}
