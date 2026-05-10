{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.coding.cpp;
in {
  options.coding.cpp.enable =
    lib.mkEnableOption "C/C++ development tooling"
    // {
      description = "Installs gcc, gdb, cmake, ninja, clang-tools, pkg-config for C/C++ development.";
    };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gcc
      mold
      lld
      libgcc
      gdb
      cmake
      gnumake
      ninja
      clang-tools
      clang
      pkg-config
      libllvm.out # for addr2line
      jetbrains.clion # uni requirement...
    ];
  };
}
