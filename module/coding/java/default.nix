{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.coding.java;
in
{
  options.coding.java.enable = lib.mkEnableOption "Java development tooling" // {
    description = "Installs jdk (LTS), maven, gradle for Java development.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jdk
      maven
      gradle
    ];
  };
}
