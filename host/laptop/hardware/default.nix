{...}: {
  modules.hardware.power.enable = true;

  modules.hardware.graphics = {
    enable = true;
    intel.enable = true;
    nvidia = {
      enable = true;
      hybrid = {
        enable = true;
        igpuVendor = "intel";
        igpuBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    vaapi = {
      enable = true;
      firefox.enable = true;
    };
  };
}
