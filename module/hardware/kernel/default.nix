{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.kernel;
  kernelAttr = "linuxPackages_${cfg.package}";
in {
  options.modules.hardware.kernel = {
    package = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      example = "xanmod_latest";
      description = "Kernel package family suffix used to select pkgs.linuxPackages_<suffix>.";
    };
    kernelPackages = lib.mkOption {
      type = lib.types.nullOr lib.types.raw;
      default = null;
      description = "Direct kernel packages override. Takes precedence over `package`.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.kernelPackages != null || builtins.hasAttr kernelAttr pkgs;
        message = "Kernel package set `${kernelAttr}` does not exist in nixpkgs.";
      }
    ];

    boot.kernelPackages =
      if cfg.kernelPackages != null
      then cfg.kernelPackages
      else pkgs.${kernelAttr};
  };
}
