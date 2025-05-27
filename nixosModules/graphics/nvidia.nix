

{ pkgs, config, lib, ... }: {
  options = {
    graphicsModule = {
      nvidia = {
        enable = lib.mkEnableOption "Enable nVidia graphics card";
        boost = lib.mkEnableOption "Enable dynamic boost option";
        hybrid = {
          enable = lib.mkEnableOption "Enable nVidia optimus prime";
          igpu = {
            vendor = lib.mkOption {
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
    nix.settings = {
      extra-substituters = [
        "https://cuda-maintainers.cachix.org"
        "https://aseipp-nix-cache.global.ssl.fastly.net"
      ];
      extra-trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
    boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" ];
    boot.kernelModules = [ "nvidia-drm.fbdev=1" ];
    boot.blacklistedKernelModules = [ "nouveau" ];

    services.xserver.videoDrivers = [ "nvidia" ];
    environment.systemPackages = [ pkgs.zenith-nvidia pkgs.hello ]; # view gpu usage

    hardware.nvidia = {
      modesetting.enable = true;
      dynamicBoost.enable = cfg.boost;

      powerManagement = {
        enable = cfg.hybrid.enable; #true;
        finegrained = cfg.hybrid.enable;
      };

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      open = false;
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
