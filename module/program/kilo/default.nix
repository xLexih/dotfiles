{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.program.app.kilo;
in {
  options.program.app.kilo.enable = lib.mkEnableOption "Kilo Code CLI" // {
    description = "Kilo Code CLI - AI-powered coding assistant installed via pnpm FHS environment";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.kilo
    ];
  };
}
