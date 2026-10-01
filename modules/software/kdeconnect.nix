{
  config,
  lib,
  users ? [],
  ...
}: let
  cfg = config.modules.software.kdeconnect;
in {
  options.modules.software.kdeconnect = {
    enable = lib.mkEnableOption "KDE Connect device integration";
  };

  config = lib.mkIf cfg.enable {
    programs.kdeconnect.enable = true;
    programs.ydotool.enable = true;
    hardware.uinput.enable = true;

    users.users = lib.genAttrs users (_: {
      extraGroups = [
        "uinput"
        config.programs.ydotool.group
      ];
    });
  };
}
