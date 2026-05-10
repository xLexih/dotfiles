{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.drawing;
in
{
  options.program.app.drawing.enable = lib.mkEnableOption "Drawing tools (Krita)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (pkgs.symlinkJoin {
        name = "krita-scaled";
        paths = [ krita ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/krita \
            --set QT_SCALE_FACTOR 1.5
        '';
      })
      krita-plugin-gmic
    ];
  };
}
