{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.media;
in
{
  options.program.app.media.enable = lib.mkEnableOption "Media editing tools (gimp, inkscape)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inkscape
      gimp
    ];
  };
}
