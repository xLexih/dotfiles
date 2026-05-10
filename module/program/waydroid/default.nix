{
  lib,
  config,
  ...
}: let
  cfg = config.program.app.waydroid;
in {
  options.program.app.waydroid.enable = lib.mkEnableOption "Waydroid to simulate android";

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
    # environment.systemPackages = with pkgs; [
    #   waydroid
    # ];
  };
}
