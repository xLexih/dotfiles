{
  config,
  lib,
  ...
}: let
  cfg = config.modules.software.docker;
in {
  options.modules.software.docker = {
    enable = lib.mkEnableOption "Docker container runtime";
    nvidia.enable = lib.mkEnableOption "NVIDIA container toolkit";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false; # start on demand
      daemon.settings.insecure-registries = ["localhost:5000"];
    };

    hardware.nvidia-container-toolkit.enable = cfg.nvidia.enable;
  };
}
