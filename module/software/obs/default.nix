{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.software.obs;
in {
  options.modules.software.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs # wayland screen capture
        obs-pipewire-audio-capture # pipewire audio
        obs-move-transition # move transitions
      ];
    };

    boot.kernelModules = ["v4l2loopback"];
    boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
    boot.extraModprobeConfig = ''
      options v4l2loopback video_nr=10 card_label="OBS Virtual Camera"
    '';
  };
}
