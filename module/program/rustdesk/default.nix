{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.rustdesk;
in
{
  options.program.app.rustdesk.enable = lib.mkEnableOption "RustDesk remote desktop";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rustdesk-flutter
    ];
  };
}
