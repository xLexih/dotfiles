{
  pkgs,
  config,
  lib,
  ...
}: {
  options = {
    graphicsModule = {
      nvidia = {
        enable = lib.mkEnableOption "Enable nVidia graphics card";
        hybrid = {
          enable = lib.mkEnableOption "Enable nVidia optimus prime";
          igpu = {
            vendor = lib.mkOption {
              type = lib.types.enum ["amd" "intel"];
              default = "amd";
            };
            port = lib.mkOption {
              default = "";
              description = "Bus Port of igpu";
            };
          };
          dgpu.port = lib.mkOption {
            default = "";
            description = "Bus Port of dgpu";
          };
        };
      };
    };
  };

  config = let
    cfg = config.graphicsModule.nvidia;
  in
    lib.mkIf cfg.enable {
      services.xserver.videoDrivers = ["nvidia"];
      environment.systemPackages = with pkgs; [
        libva # hardware acceleration nvidia
        mesa # mesa
        libva-utils # hardware acceleration nvidia
        libvdpau-va-gl # more libva~
        libGL # GL
        gwe
        nvtopPackages.nvidia # to check usage of nvidia gpus
        cudaPackages.cuda_cudart
        cudaPackages.cuda_nvcc
        cudaPackages.cuda_cccl
      ];
      boot.kernelParams = [
        "nvidia_drm.modeset=1"
        "nvidia_drm.fbdev=0"
        # NVIDIA-specific fixes
        "nvidia.NVreg_EnablePCIeGen3=1"
        "nvidia.NVreg_UsePageAttributeTable=1"
        "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
        "nvidia.NVreg_DynamicPowerManagement=0x02" # ADD THIS
      ];
      boot.kernelModules = [
        "nvidia"
        "nvidia_drm"
        "nvidia_uvm"
        "nvidia_modeset"
      ];
      # Set environment variables related to NVIDIA graphics
      environment.variables = {
        # Required to run the correct GBM backend for nvidia GPUs on wayland
        GBM_BACKEND = "nvidia-drm";
        # Apparently, without this nouveau may attempt to be used instead
        # (despite it being blacklisted)
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        # Hardware cursors are currently broken on nvidia
        LIBVA_DRIVER_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        __GL_THREADED_OPTIMIZATION = "1";
        __GL_SHADER_CACHE = "1";
      };
      services.udev.extraRules = ''
        # NVIDIA device nodes with proper permissions
        KERNEL=="nvidia", MODE="0666", GROUP="video"
        KERNEL=="nvidiactl", MODE="0666", GROUP="video"
        KERNEL=="nvidia-modeset", MODE="0666", GROUP="video"
        KERNEL=="nvidia-uvm", MODE="0666", GROUP="video"
        KERNEL=="nvidia[0-9]*", MODE="0666", GROUP="video"
      '';
      boot.extraModprobeConfig = ''
        # CORRECT NVIDIA PARAMETERS (remove invalid ones)
        options nvidia NVreg_UsePageAttributeTable=1
        options nvidia NVreg_EnablePCIeGen3=1
        options nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100

        # Remove these invalid parameters:
        # NVreg_UseThreadedInterrupts - doesn't exist in this driver version
        # NVreg_EnableGpuFirmware - doesn't exist in this driver version
      '';

      hardware.nvidia = {
        # General stuff~
        open = true;
        modesetting.enable = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        vaapi = {
          enable = true;
          firefox.enable = true;
        };
        # Laptop stuff (dual gpu idk haven't tried it on my main one yet)
        dynamicBoost.enable = cfg.hybrid.enable;
        powerManagement = {
          enable = cfg.hybrid.enable;
          finegrained = false; # cfg.hybrid.enable;
        };
        prime = lib.mkIf cfg.hybrid.enable {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          amdgpuBusId = lib.mkIf (cfg.hybrid.igpu.vendor == "amd") cfg.hybrid.igpu.port;
          intelBusId = lib.mkIf (cfg.hybrid.igpu.vendor == "intel") cfg.hybrid.igpu.port;
          nvidiaBusId = cfg.hybrid.dgpu.port;
        };
      };
    };
}
