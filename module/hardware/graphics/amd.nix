{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.graphics;
in {
  options.modules.hardware.graphics.amd = {
    enable = lib.mkEnableOption "AMD graphics";
  };

  config = lib.mkIf (cfg.enable && cfg.amd.enable) {
    services.xserver.videoDrivers = ["amdgpu"];

    hardware.graphics = {
      extraPackages = with pkgs; [
        rocmPackages.clr.icd # OpenCL runtime
        libva-vdpau-driver # VA-API via VDPAU
        libvdpau-va-gl # VDPAU via VA-API
      ];
      extraPackages32 = [];
    };

    environment.systemPackages = with pkgs; [
      radeontop # GPU usage monitor
      nvtopPackages.amd # GPU process monitor
    ];

    # amd hip workaround
    systemd.tmpfiles.rules = [
      "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
    ];
  };
}
