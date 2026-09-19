{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.warp;
in {
  options.modules.software.warp = {
    enable = lib.mkEnableOption "Cloudflare WARP daemon (warp-svc + warp-cli)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.cloudflare-warp];

    systemd.services.warp-svc = {
      description = "Cloudflare WARP Daemon";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = "cloudflare-warp";
      };
    };
  };
}
