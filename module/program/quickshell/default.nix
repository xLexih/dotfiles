{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.program.app.quickshell;
in {
  options.program.app.quickshell.enable = lib.mkEnableOption "Quickshell bar";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
      qt6.qt5compat
      qt6.qtbase
      qt6.qtquick3d
      qt6.qtwayland
      qt6.qtdeclarative
      qt6.qtsvg

      kdePackages.qt5compat
      libsForQt5.qt5.qtgraphicaleffects
    ];

    environment.variables = {
      QML2_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtbase}/lib/qt-6/qml";
    };

    environment.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };
}
