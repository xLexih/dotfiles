{ config, pkgs,lib, ... }:

{
  virtualisation.docker.enableOnBoot = false;
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    wantedBy = lib.mkForce [ "docker.service" ];
    before = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
  };
  systemd.services.docker = {
    requires = [];
    wants = [ "network.target" ];
    after = [ "network.target" ];
    before = [ "multi-user.target" ];
  };
}