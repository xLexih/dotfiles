{
  config,
  lib,
  ...
}: let
  cfg = config.modules.services.ssh;
in {
  options.modules.services.ssh.enable = lib.mkEnableOption "the OpenSSH server (installed and firewalled open, started manually with `systemctl start sshd`)";

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      startWhenNeeded = false;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    systemd.services.sshd.wantedBy = lib.mkForce [];
  };
}
