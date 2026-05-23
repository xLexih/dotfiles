{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.kernel;
  kernelAttr = "linuxPackages_${cfg.package}";
in {
  options.modules.hardware.kernel.package = lib.mkOption {
    type = lib.types.str;
    default = "latest";
    example = "xanmod_latest";
    description = "Kernel package family suffix used to select pkgs.${kernelAttr}.";
  };

  config = {
    assertions = [
      {
        assertion = builtins.hasAttr kernelAttr pkgs;
        message = "Kernel package set `${kernelAttr}` does not exist in nixpkgs.";
      }
    ];

    boot.kernelPackages = pkgs.${kernelAttr};
  };
}
