{pkgs, lib, config, ...}: {
  imports = [
    ./amd.nix
    ./nvidia.nix
    ./intel.nix
    ./vaapi.nix
  ];
  options = {
    graphicsModule = {
      dgpu = lib.mkOption {
        description = "lscpi | grep -E 'VGA|3D' the format from /dev/dri/by-path";
      };
      igpu = lib.mkOption {
        description = "lscpi | grep -E 'VGA|3D' the format from /dev/dri/by-path";
      };
    };
  };
  # hardware.opengl.enable = true;
  config.hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ vulkan-loader ];
      extraPackages32 = with pkgs; [ vulkan-loader ];
    };
  };
}
