{
  lib,
  config,
  pkgs,
  settings,
  ...
}:
let
  cfg = config.program.app.lutris;
in
{
  options.program.app.lutris.enable = lib.mkEnableOption "Lutris game launcher with Wine";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris
      wineWow64Packages.stable
      wineWow64Packages.staging
      winetricks
      wineWow64Packages.waylandFull

      mono
      samba
      krb5
      cabextract
      unzip
      p7zip

      vkd3d-proton
      dxvk
      vulkan-loader
      vulkan-tools
    ];
    hjem.users = lib.attrsets.genAttrs settings.users (username: {
      files = {
        ".local/share/lutris/runners/proton/GE-Proton".source = pkgs.proton-ge-bin.steamcompattool;
      };
    });
  };
}
