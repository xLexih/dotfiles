{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.opencode;
in
{
  options.program.app.opencode.enable = lib.mkEnableOption "opencode" // {
    description = "OpenCode - AI coding agent built for the terminal";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.opencode
    ];
  };
}
