{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.greetd;
in {
  options.modules.desktop.greetd = {
    enable = lib.mkEnableOption "the greetd login manager with tuigreet";
    command = lib.mkOption {
      type = lib.types.str;
      default = "start-hyprland";
      description = "Session command started after login.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${lib.getExe pkgs.tuigreet} --time --cmd ${cfg.command}";
        user = "greeter";
      };
    };
  };
}
