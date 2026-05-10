{
  lib,
  config,
  ...
}: {
  imports = [
    ./docker.nix
    ./network_manager.nix
    ./kernal.nix
  ];

  hardware.enableAllFirmware = lib.mkDefault true;
  systemd.tmpfiles.rules = [
    "d /tmp/.X11-unix 1777 root root -"
  ];

  hardware.bluetooth = {
    powerOnBoot = lib.mkDefault false;
    settings = {
      General = {
        FastConnectable = lib.mkDefault false;
      };
    };
  };
  systemd.services.nvidia-powerd = {
    before = lib.mkForce [];
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  boot.initrd.checkJournalingFS = false;
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
    DefaultTimeoutStartSec = "10s";
  };

  boot.consoleLogLevel = 3;
  boot.kernel.sysctl."kernel.printk" = "3 4 1 3";

  virtualisation.libvirtd = lib.mkIf config.program.app.virtual-machine.enable {
    onBoot = lib.mkForce "ignore";
    onShutdown = "shutdown";
  };

  systemd.sockets.libvirtd = lib.mkIf config.program.app.virtual-machine.enable {
    wantedBy = ["sockets.target"];
  };

  systemd.services.libvirtd = lib.mkIf config.program.app.virtual-machine.enable {
    wantedBy = lib.mkForce [];
    requires = ["libvirtd.socket"];
    after = ["libvirtd.socket"];
  };

  systemd.services.libvirt-guests = lib.mkIf config.program.app.virtual-machine.enable {
    wantedBy = lib.mkForce [];
  };

  systemd.services.spice-vdagentd = lib.mkIf config.program.app.virtual-machine.enable {
    wantedBy = lib.mkForce [];
  };
}
