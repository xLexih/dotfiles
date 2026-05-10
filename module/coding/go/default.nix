{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.coding.go;
in {
  options.coding.go.enable =
    lib.mkEnableOption "Go development tooling"
    // {
      description = "Installs Go toolchain and development tools.";
    };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      go
      gopls
      go-tools
      delve
    ];
  };
}
