# The mainline uniwill-laptop driver supports this barebone (TUXEDO Stellaris
# 16 Gen6, GM6IXxB) but matches on DMI vendor TUXEDO. Its `force=1` would
# enable every EC feature, including ones this board lacks (EC lightbar, USB-C
# power priority) whose init writes EC registers. This copy, renamed to
# uniwill_gm6ix, uses TUXEDO's descriptor for this board under `force=1`:
# charge modes, fan and temperature sensors, NVIDIA cTGP/Dynamic Boost.
#
# Not loaded automatically. Its charge modes don't limit charging on this
# unit: Trickle ended a charge at the same voltage as Standard (see
# docs/power.md). Load it for the fan and EC temperature sensors:
#   sudo modprobe uniwill_gm6ix force=1
{config, ...}: let
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
}
