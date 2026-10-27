# The mainline uniwill-laptop driver supports this barebone (TUXEDO Stellaris
# 16 Gen6, GM6IXxB) but matches on DMI vendor TUXEDO. Its `force=1` would
# enable every EC feature, including ones this board lacks (EC lightbar, USB-C
# power priority) whose init writes EC registers. This copy, renamed to
# uniwill_gm6ix, uses TUXEDO's descriptor for this board under `force=1`:
# charge modes, fan and temperature sensors, NVIDIA cTGP/Dynamic Boost.
#
# Not loaded automatically: the same chassis from another reseller accepted
# the charge mode but kept charging to 100%. Test before adding it to
# boot.kernelModules (see README):
#   sudo modprobe uniwill_gm6ix force=1
{
  config,
  pkgs,
  ...
}: let
  uniwill-gm6ix = config.boot.kernelPackages.callPackage ({
    stdenv,
    kernel,
    kernelModuleMakeFlags,
  }:
    stdenv.mkDerivation {
      pname = "uniwill-gm6ix";
      inherit (kernel) version;
      src = "${kernel.src}/drivers/platform/x86/uniwill";

      postPatch = ''
        substituteInPlace uniwill-acpi.c \
          --replace-fail 'device_descriptor.features = UINT_MAX & ~UNIWILL_FEATURE_BATTERY_CHARGE_LIMIT;' \
                         'device_descriptor = tux_featureset_3_nvidia_descriptor;' \
          --replace-fail 'Enabling potentially unsupported features' 'Using the GM6IXxB feature set'
        printf '%s\n' 'obj-m := uniwill-gm6ix.o' 'uniwill-gm6ix-y := uniwill-acpi.o uniwill-wmi.o' > Kbuild
      '';

      nativeBuildInputs = kernel.moduleBuildDependencies;
      makeFlags =
        kernelModuleMakeFlags
        ++ [
          "-C"
          "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
          "INSTALL_MOD_PATH=${placeholder "out"}"
          "INSTALL_MOD_DIR=extra"
          "DEPMOD=true"
        ];
      preBuild = ''makeFlagsArray+=("M=$PWD")'';
      buildFlags = ["modules"];
      installTargets = ["modules_install"];
    }) {};
in {
  boot.extraModulePackages = [uniwill-gm6ix];

  # "Trickle" is TUXEDO's Stationary profile (charges to 80%); "Long Life" is
  # Balanced (90%), "Standard" charges to 100%. Set whenever the driver binds;
  # it restores the mode itself after suspend.
  services.udev.extraRules = ''
    ACTION=="bind", SUBSYSTEM=="platform", DRIVER=="uniwill", RUN+="${pkgs.bash}/bin/sh -c 'echo Trickle > /sys/class/power_supply/BAT0/charge_types'"
  '';
}
