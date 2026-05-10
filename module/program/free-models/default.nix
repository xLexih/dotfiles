{ lib, config, pkgs, ... }:
let
  cfg = config.program.app.free-models;
in
{
  options.program.app.free-models.enable = lib.mkEnableOption "free-models CLI" // {
    description = "free-models CLI - Find free NVIDIA models via FHS environment";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.free-models
    ];
  };
}
