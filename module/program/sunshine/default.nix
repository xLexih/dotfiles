{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.sunshine;
in
{
  options.program.app.sunshine.enable = lib.mkEnableOption "Sunshine game streaming server";

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    boot.kernelModules = [ "uinput" ];

    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;

    environment.systemPackages = with pkgs; [
      xrandr
    ];
  };
}
