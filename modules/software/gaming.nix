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
    # gamemoderun preloads these from the host inside Steam's container.
    environment.sessionVariables.PRESSURE_VESSEL_FILESYSTEMS_RO = lib.makeLibraryPath [
      pkgs.gamemode
      pkgs.pkgsi686Linux.gamemode
    ];

    # Recent Wine and Proton use /dev/ntsync for NT synchronization when it
    # exists, cutting the CPU overhead of esync/fsync in heavily threaded games.
    boot.kernelModules = ["ntsync"];

    programs.steam = {
      enable = true;
      extest.enable = true;
      gamescopeSession.enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
      package = pkgs.steam.override {
        # Native games that bypass the Steam Runtime load these from the FHS env.
        extraLibraries = p:
          with p; [
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
          ];
        # Games run on the NVIDIA GPU on hybrid laptops (no-op elsewhere).
        extraProfile = ''
          unset DRI_PRIME
          ${nvidia.offloadShell}
        '';
      };
      protontricks.enable = true;
    };

    programs.gamemode = {
      enable = true;
      # Raises the game's priority over background work (via CAP_SYS_NICE).
      settings.general.renice = 10;
    };

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
    ];
  };
}
