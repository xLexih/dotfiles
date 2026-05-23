{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.sunshine;
in {
  options.modules.software.sunshine = {
    enable = lib.mkEnableOption "Sunshine game streaming server";
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    boot.kernelModules = ["uinput"];

    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    environment.systemPackages = with pkgs; [
      xrandr # display configuration
    ];
  };
}
