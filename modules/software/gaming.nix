{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.gaming;
  nvidia = config.modules.hardware.graphics.nvidia;
in {
  options.modules.software.gaming = {
    enable = lib.mkEnableOption "gaming compatibility stack";
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables.PRESSURE_VESSEL_FILESYSTEMS_RO = lib.makeLibraryPath [
      pkgs.gamemode
      pkgs.pkgsi686Linux.gamemode
    ];

    programs.steam = {
      enable = true;
      extest.enable = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        libXcursor
        libXi
        libXinerama
        libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
        proton-ge-bin
      ];
      # Games run on the NVIDIA GPU on hybrid laptops (no-op elsewhere).
      package = pkgs.steam.override {
        extraProfile = ''
          unset DRI_PRIME
          ${nvidia.offloadShell}
        '';
      };
      protontricks.enable = true;
    };

    programs.gamemode.enable = true;

    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    environment.systemPackages = with pkgs; [
      goverlay
      (nvidia.offload heroic)
      mangohud
      protonup-qt
      umu-launcher
      gamemode
    ];
  };
}
