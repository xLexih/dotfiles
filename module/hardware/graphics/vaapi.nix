{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.graphics;
in {
  options.modules.hardware.graphics.vaapi = {
    enable = lib.mkEnableOption "NVIDIA VA-API support";
    maxInstances = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Max concurrent driver instances (useful for low VRAM)";
    };
    firefox.enable = lib.mkEnableOption "Firefox VA-API integration";
  };

  config = lib.mkIf (cfg.enable && cfg.nvidia.enable && cfg.vaapi.enable) {
    environment.variables =
      {
        NVD_BACKEND = "direct";
      }
      // lib.optionalAttrs (cfg.vaapi.maxInstances != null) {
        NVD_MAX_INSTANCES = toString cfg.vaapi.maxInstances;
      }
      // lib.optionalAttrs cfg.vaapi.firefox.enable {
        MOZ_DISABLE_RDD_SANDBOX = "1";
      };
  };
}
