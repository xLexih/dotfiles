{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.session.greetd;
in {
  options.modules.session.greetd = {
    enable = lib.mkEnableOption "greetd display manager";
    command = lib.mkOption {
      type = lib.types.str;
      default = "start-hyprland";
      description = "Session command to launch after login";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${cfg.command}";
        user = "greeter";
      };
    };
  };
}
