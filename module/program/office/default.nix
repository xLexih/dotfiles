{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.office;
in
{
  options.program.app.office.enable =
    lib.mkEnableOption "Office suite (LibreOffice, OnlyOffice, Zotero)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      onlyoffice-desktopeditors
      libreoffice-qt6-fresh
      zotero
    ];
    fonts.packages = with pkgs; [
      corefonts
    ];
  };
}
