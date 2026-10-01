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
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start Sunshine automatically at boot.";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for Sunshine.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = cfg.autoStart;
      capSysAdmin = true;
      openFirewall = cfg.openFirewall;
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
