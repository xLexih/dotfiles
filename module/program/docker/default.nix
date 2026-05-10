{ lib, config, ... }:
let
  cfg = config.program.app.docker;
in
{
  options.program.app.docker.enable = lib.mkEnableOption "Docker with NVIDIA container toolkit";

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      daemon.settings = {
        insecure-registries = [ "localhost:5000" ];
      };
    };
    hardware.nvidia-container-toolkit.enable = true;
  };
}
