{...}: {
  imports = [
    ./amd.nix
    ./nvidia.nix
    ./intel.nix
  ];
  hardware.opengl.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}