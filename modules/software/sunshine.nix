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

    # nixpkgs' sunshine module still sets the obsolete
    # `services.avahi.publish.{enable,userServices}` options (defaults for
    # its own avahi block); null them so only `settings.publish` applies and
    # the deprecation warnings stay quiet.
    services.avahi.publish.enable = lib.mkOverride 90 null;
    services.avahi.publish.userServices = lib.mkOverride 100 null;

    boot.kernelModules = ["uinput"];

    environment.systemPackages = with pkgs; [
      xrandr # display configuration
    ];
  };
}
