{
  config,
  lib,
  ...
}: let
  cfg = config.modules.software.waydroid;
in {
  options.modules.software.waydroid = {
    enable = lib.mkEnableOption "Waydroid Android emulation";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
  };
}
