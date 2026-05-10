{ lib, config, pkgs, ... }:
let
  cfg = config.program.app.adb;
in
{
  options.program.app.adb = {
    enable = lib.mkEnableOption "ADB tooling for a user";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;[
      android-tools
    ];
  };
}
