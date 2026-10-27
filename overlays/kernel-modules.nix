# Out-of-tree module fixes for the CachyOS kernel sets, until nixpkgs catches up:
# - tuxedo-drivers' Makefile re-passes $(MAKEFLAGS) through the shell, which
#   chokes on the `$(space)` in the kmodigest `cmd_sign` flag; a sub-make
#   inherits those flags anyway (https://github.com/NixOS/nixpkgs/issues/576266).
#   (v4l2loopback and acpi_call already carry DEPMOD=true upstream; nothing to
#   override there.)
# - yt6801 skips kernelModuleMakeFlags, so its module is never signed and the
#   aggregated tree misses yt6801.ko.cer
#   (https://github.com/NixOS/nixpkgs/issues/575192). Fixed on nixpkgs master
#   but not yet in nixos-unstable; drop this override once it lands there.
final: prev: let
  inherit (prev) lib;
  fix = kfinal: kprev: {
    tuxedo-drivers = kprev.tuxedo-drivers.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace Makefile --replace-fail ' $(MAKEFLAGS)' ""
        '';
    });
    yt6801 = kprev.yt6801.overrideAttrs (old: {
      makeFlags = kfinal.kernelModuleMakeFlags ++ old.makeFlags;
    });
  };
in {
  cachyosKernels =
    lib.mapAttrs
    (name: set:
      if lib.hasPrefix "linuxPackages-" name
      then set.extend fix
      else set)
    prev.cachyosKernels;
}
