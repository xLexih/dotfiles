{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.coding.sql;
in
{
  options.coding.sql.enable = lib.mkEnableOption "MYSQL workench for uni" // {
    description = "Installs MYSQL workbench.";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mysql-workbench
    ];
  };
}
