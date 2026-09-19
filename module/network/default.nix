{
  config,
  lib,
  ...
}: let
  cfg = config.modules.network.sshd;
in {
  options.modules.network.sshd = {
    enable = lib.mkEnableOption "OpenSSH server (sshd, manual start, disabled by default)";
  };

  config = {
    boot.kernelModules = ["tun"];

    networking.nftables.enable = true; # modern firewall backend

    networking.networkmanager = {
      enable = true;
      wifi.powersave = false; # disable wifi powersave
      wifi.macAddress = "random"; # privacy
      connectionConfig."connection.mdns" = 2;
      connectionConfig."ipv6.ip6-privacy" = 2; # temporary addresses
      dhcp = "internal"; # faster than dhclient
    };

    networking.firewall = {
      enable = true;
      allowPing = true;
    };

    services.openssh = {
      enable = cfg.enable;
      startWhenNeeded = false; # no socket activation; start manually with `systemctl start sshd`
      openFirewall = cfg.enable; # only open port 22 when sshd is enabled
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Disabled by default: available via `systemctl start sshd`, never autostarted.
    systemd.services.sshd.wantedBy = lib.mkIf cfg.enable (lib.mkForce []);

    services.resolved.enable = true; # modern dns resolution

    services.avahi = {
      enable = true;
      nssmdns4 = true; # .local hostname resolution
      openFirewall = true;
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false; # saves power
      settings.General.ControllerMode = "dual"; # br/edr + le
      settings.General.Experimental = true;
    };
    services.blueman.enable = true; # bluetooth gui
  };
}
