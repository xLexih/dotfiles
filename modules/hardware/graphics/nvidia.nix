{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.graphics;
  hybrid = cfg.nvidia.hybrid;

  # "PCI:0:2:0" -> "0000:00:02.0"
  pciAddress = busId: let
    parts = lib.splitString ":" busId;
    hex = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString (lib.toInt n)));
  in "0000:${hex (lib.elemAt parts 1)}:${hex (lib.elemAt parts 2)}.${lib.elemAt parts 3}";

  igpuVulkan =
    {
      intel = "intel_icd";
      amd = "radeon_icd";
    }.${
      hybrid.igpuVendor
    };

  # Runs a program on the NVIDIA GPU, undoing the offloadOnly restrictions.
  offloadShell = ''
    export __NV_PRIME_RENDER_OFFLOAD=1 __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only
    unset __EGL_VENDOR_LIBRARY_FILENAMES VK_DRIVER_FILES MOZ_DRM_DEVICE
  '';

  nvidiaOffload = pkgs.writeShellScriptBin "nvidia-offload" ''
    ${offloadShell}
    exec "$@"
  '';

  # Every binary of `pkg` runs offloaded; desktop entries point at the wrappers.
  wrapOffload = pkg:
    pkgs.symlinkJoin {
      name = "${pkg.name}-nvidia-offload";
      paths = [pkg];
      nativeBuildInputs = [pkgs.lndir pkgs.makeWrapper];
      postBuild = ''
        # Directories linked as a whole can't be modified; recreate them.
        own() {
          if [ -L "$1" ]; then
            target=$(readlink -f "$1")
            rm "$1"
            mkdir "$1"
            lndir -silent "$target" "$1"
          fi
        }
        own $out/bin
        own $out/share
        own $out/share/applications

        for bin in $out/bin/*; do
          wrapProgram "$bin" --run ${lib.escapeShellArg offloadShell}
        done
        for entry in $out/share/applications/*.desktop; do
          [ -e "$entry" ] || continue
          target=$(readlink -f "$entry")
          rm "$entry"
          sed "s|${pkg}/bin|$out/bin|g" "$target" > "$entry"
        done
      '';
      inherit (pkg) meta;
    };

  offloadOnly = cfg.enable && cfg.nvidia.enable && hybrid.enable && hybrid.offloadOnly;
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
        default = hybrid.offloadOnly;
        description = "Remove the NVIDIA HDMI audio function so the GPU can power off completely.";
      };
      offloadOnly = lib.mkEnableOption ''
        keeping the NVIDIA GPU powered off unless asked for. OpenGL/EGL and
        Vulkan programs only see the integrated GPU; `nvidia-offload <cmd>` and
        packages wrapped with `modules.hardware.graphics.nvidia.offload` (game
        launchers) use the NVIDIA GPU. Without this, browsers, Electron apps and
        Xwayland load the NVIDIA driver and keep the GPU awake
      '';
    };

    offload = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      default =
        if offloadOnly
        then wrapOffload
        else lib.id;
      description = "Wraps a package to run on the NVIDIA GPU when `hybrid.offloadOnly` is set; returns it unchanged otherwise.";
    };

    offloadShell = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = lib.optionalString offloadOnly offloadShell;
      description = "Shell snippet that switches to the NVIDIA GPU, for launchers configured through a profile script (Steam).";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.nvidia.enable) (lib.mkMerge [
    {
      services.xserver.videoDrivers = ["nvidia"];

      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.production;
        # Laptop-only: desktop cards support neither (no runtime D3, and
        # nvidia-powerd quits on them).
        dynamicBoost.enable = hybrid.enable;
        powerManagement = {
          # Saves video memory across suspend.
          enable = true;
          finegrained = hybrid.enable;
        };
        prime = lib.mkIf hybrid.enable (
          {
            offload.enable = true;
            nvidiaBusId = hybrid.nvidiaBusId;
          }
          // (
            if hybrid.igpuVendor == "intel"
            then {intelBusId = hybrid.igpuBusId;}
            else {amdgpuBusId = hybrid.igpuBusId;}
          )
        );
      };

      boot.kernelParams = [
        "nvidia_drm.modeset=1"
        "nvidia_drm.fbdev=1"
        "nvidia.NVreg_UsePageAttributeTable=1"
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        # Skips zeroing system memory the driver allocates (CachyOS default).
        "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
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
    }

    (lib.mkIf hybrid.enable {
      environment.systemPackages = [nvidiaOffload];
      # Lets the GPU power off when idle (runtime D3).
      boot.kernelParams = ["nvidia.NVreg_DynamicPowerManagement=0x02"];
    })

    # With the audio function bound, the GPU's PCIe slot can't reach D3cold.
    (lib.mkIf hybrid.blacklistHdmiAudio {
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
      '';
    })

    (lib.mkIf offloadOnly {
      environment.sessionVariables = {
        __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
        VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/${igpuVulkan}.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/${igpuVulkan}.i686.json";
        # Firefox's video decoder otherwise probes the NVIDIA render node.
        MOZ_DRM_DEVICE = "/dev/dri/by-path/pci-${pciAddress hybrid.igpuBusId}-render";
      };
    })
  ]);
}
