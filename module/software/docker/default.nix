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
    insecureRegistries = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["localhost:5000"];
      description = "Docker insecure registries for local development.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false; # start on demand
      daemon.settings.insecure-registries = cfg.insecureRegistries;
    };

    hardware.nvidia-container-toolkit.enable = cfg.nvidia.enable;
  };
}
