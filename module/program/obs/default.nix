{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.program.app.obs;
in {
  options.program.app.obs.enable = lib.mkEnableOption "OBS Studio with plugins";

  config = lib.mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
        obs-move-transition
      ];
    };
    boot.extraModprobeConfig = lib.mkForce ''
      options v4l2loopback devices=1 video_nr=1 card_label="FHD WebCam: DIY Cam" exclusive_caps=1
    '';
  };
}
