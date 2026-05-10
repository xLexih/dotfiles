{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.networking-tools;
in
{
  options.program.app.networking-tools.enable = lib.mkEnableOption "Network diagnostic tools";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nettools
      tcpdump
      traceroute
      mtr
      dig
    ];
  };
}
