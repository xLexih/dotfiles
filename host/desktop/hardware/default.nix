{...}: {
  modules.hardware.graphics = {
    enable = true;
    amd.enable = true;
    nvidia = {
      enable = true;
      hybrid = {
        enable = true;
        igpuVendor = "amd";
        igpuBusId = "PCI:16:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    vaapi = {
      enable = true;
      firefox.enable = true;
    };
  };
}
