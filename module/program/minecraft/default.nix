{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.minecraft;
in
{
  options.program.app.minecraft.enable = lib.mkEnableOption "PrismLauncher for Minecraft";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      prismlauncher
    ];
  };
}
