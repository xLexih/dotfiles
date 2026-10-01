{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.cpu;
in {
  options.modules.hardware.cpu.vendor = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["amd" "intel"]);
    default = null;
    description = "CPU vendor for host-specific tuning and microcode.";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.vendor == "intel") {
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    })
    (lib.mkIf (cfg.vendor == "amd") {
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    })
  ];
}
