{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.program.app.ani-cli;
in {
  options.program.app.ani-cli.enable = lib.mkEnableOption "ani-cli" // {
    description = "ani-cli - A cli to browse and watch anime";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.ani-cli
    ];
  };
}
