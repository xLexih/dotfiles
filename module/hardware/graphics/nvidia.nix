{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.graphics;
in {
  options.modules.hardware.graphics.nvidia = {
    enable = lib.mkEnableOption "NVIDIA dedicated graphics";
    hybrid = {
      enable = lib.mkEnableOption "PRIME hybrid offload";
      igpuVendor = lib.mkOption {
        type = lib.types.enum ["amd" "intel"];
        default = "intel";
        description = "Integrated GPU vendor used for PRIME offload.";
      };
      igpuBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "PCI bus ID of the integrated GPU (e.g. PCI:0:2:0)";
      };
      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "PCI bus ID of the NVIDIA dGPU (e.g. PCI:1:0:0)";
      };
      blacklistHdmiAudio = lib.mkOption {
        type = lib.types.bool;
        default = cfg.nvidia.hybrid.enable;
        description = "Blacklist NVIDIA HDMI audio to allow full GPU power-down.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.nvidia.enable) {
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      dynamicBoost.enable = cfg.nvidia.hybrid.enable;
      powerManagement = {
        enable = cfg.nvidia.hybrid.enable;
        finegrained = cfg.nvidia.hybrid.enable;
      };
      prime = lib.mkIf cfg.nvidia.hybrid.enable (
        {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          nvidiaBusId = cfg.nvidia.hybrid.nvidiaBusId;
        }
        // (
          if cfg.nvidia.hybrid.igpuVendor == "intel"
          then {
            intelBusId = cfg.nvidia.hybrid.igpuBusId;
          }
          else {
            amdgpuBusId = cfg.nvidia.hybrid.igpuBusId;
          }
        )
      );
    };

    boot.kernelParams = [
      "nvidia_drm.modeset=1"
      "nvidia_drm.fbdev=1"
      "nvidia.NVreg_UsePageAttributeTable=1"
      "nvidia.NVreg_DynamicPowerManagement=0x02"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    boot.blacklistedKernelModules = lib.mkIf cfg.nvidia.hybrid.blacklistHdmiAudio [
      "snd_hda_codec_nvhdmi"
    ];

    environment.variables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      __GL_THREADED_OPTIMIZATION = "1";
      __GL_SHADER_CACHE = "1";
    };

    environment.systemPackages = with pkgs; [
      libva
      libva-utils
      nvtopPackages.nvidia
    ];
  };
}
