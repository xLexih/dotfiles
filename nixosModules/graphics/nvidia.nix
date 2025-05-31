

{ pkgs, config, settings, lib, ... }: {
  options = {
    graphicsModule = {
      nvidia = {
        enable = lib.mkEnableOption "Enable nVidia graphics card";
        boost = lib.mkEnableOption "Enable dynamic boost option";
        hybrid = {
          enable = lib.mkEnableOption "Enable nVidia optimus prime";
          igpu = {
            vendor = lib.mkOption { # lspci -nnk | grep -EA3 'VGA|3D|Display'
              type = lib.types.enum [ "amd" "intel" ];
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

  config = let cfg = config.graphicsModule.nvidia;
  in lib.mkIf cfg.enable {
    # nix.settings = {
    #   extra-substituters = [
    #     "https://cuda-maintainers.cachix.org"
    #     "https://aseipp-nix-cache.global.ssl.fastly.net"
    #   ];
    #   extra-trusted-public-keys = [
    #     "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    #   ];
    # };
    # https://discourse.nixos.org/t/nvidia-drivers-not-loading/40913/10
    boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" ];
    boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];
    boot.blacklistedKernelModules = [ "nouveau" ];
    boot.extraModulePackages = [ pkgs.${settings.kernal}.nvidia_x11 ];
    # boot.extraModulePackages = [ pkgs.linuxPackages.nvidia_x11 ];

    environment.systemPackages = with pkgs; [ 
      zenith-nvidia 
      hello 
      nvidia-vaapi-driver
      libvdpau-va-gl
      egl-wayland
      libva-utils
      vulkan-tools

    ]; # view gpu usage
    # environment.variables = {
    #   # these three are apparently required
    #   WLR_NO_HARDWARE_CURSORS = "1";
    #   GBM_BACKEND = "nvidia-drm";
    #   NVD_BACKEND = "direct";
    #   LIBVA_DRIVER_NAME = "nvidia";
    #   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    #   ELECTRON_OZONE_PLATFORM_HINT = "auto";
    # };

    services.xserver = {    
        videoDrivers = ["nvidia"];
    };

    hardware.nvidia = {
      dynamicBoost.enable = cfg.boost;

      powerManagement = {
        enable = cfg.hybrid.enable;
        finegrained = cfg.hybrid.enable;
      };

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      open = true;
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime = lib.mkIf cfg.hybrid.enable {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        amdgpuBusId =
          lib.mkIf (cfg.hybrid.igpu.vendor == "amd") cfg.hybrid.igpu.port;
        intelBusId =
          lib.mkIf (cfg.hybrid.igpu.vendor == "intel") cfg.hybrid.igpu.port;
        nvidiaBusId = cfg.hybrid.dgpu.port;
      };
    };
  };
}
