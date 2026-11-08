{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.docker;
  systemctl = "${config.systemd.package}/bin/systemctl";
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
      # Weekly, starting Docker if needed: stopped containers, unused images
      # and build cache older than a week (cache had grown past 100 GB).
      # Volumes are kept.
      autoPrune = {
        enable = true;
        flags = ["--all" "--filter" "until=168h"];
      };
    };

    hardware.nvidia-container-toolkit.enable = cfg.nvidia.enable;

    # Generate the CDI spec only when Docker runs or is starting (it waits for
    # this unit). nixpkgs also restarts the unit from udev whenever the NVIDIA
    # driver loads, which at boot cost 2.7 s and woke the NVIDIA GPU.
    systemd.services.nvidia-container-toolkit-cdi-generator = lib.mkIf cfg.nvidia.enable {
      wantedBy = lib.mkForce [];
      serviceConfig.ExecCondition = pkgs.writeShellScript "docker-starting" ''
        [ "$(${systemctl} show -P ActiveState docker.service)" != inactive ] ||
          ${systemctl} list-jobs --no-legend docker.service | ${pkgs.gnugrep}/bin/grep -q .
      '';
    };
  };
}
