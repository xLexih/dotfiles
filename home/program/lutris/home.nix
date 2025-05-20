{ pkgs, ... }:

{
  home.packages = [ pkgs.lutris ];
  home.file.".local/share/lutris/runners/proton/GE-Proton".source =
    pkgs.proton-ge-bin.steamcompattool;
  # programs.steam.enable = true;
  # environment.systemPackages =[
  #   wineWowPackages.staging
  #   wineWowPackages.stable
  #   wineWowPackages.waylandFull

  #   vulkan-tools
  #   vulkan-loader
  #   # libvulkan
  #   # libvulkan32

  #   dotnet-runtime_8
  #   mono

  #   wine
  #   wine64
  #   (wine.override { wineBuild = "wine64"; })
  #   winetricks

  #   protobuf
  #   dxvk
  #   (mesa.drivers)
  # ];
}
