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
      nix.settings = {
        extra-substituters = [
          "https://cuda-maintainers.cachix.org"
          "https://aseipp-nix-cache.global.ssl.fastly.net"
        ];
        extra-trusted-public-keys = [
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ];
      };

      services.xserver.videoDrivers = ["nvidia"];
      environment.systemPackages = with pkgs; [
        libva # hardware acceleration nvidia
        mesa # mesa
        libva-utils # hardware acceleration nvidia
        libvdpau-va-gl # more libva~
        libGL # GL
        nvtopPackages.nvidia # to check usage of nvidia gpus
      ];
      boot.kernelParams = ["nvidia_drm.modeset=1" "nvidia_drm.fbdev=1"];
      environment.variables = {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";
        NVD_BACKEND = "nvidia";
        GBM_BACKEND = "nvidia-drm";
      };

      hardware.nvidia = {
        # General stuff~
        open = true;
        modesetting.enable = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;

        # Laptop stuff (dual gpu idk haven't tried it on my main one yet)
        dynamicBoost.enable = false; # cfg.hybrid.enable;
        powerManagement = {
          enable = cfg.hybrid.enable;
          finegrained = cfg.hybrid.enable;
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
