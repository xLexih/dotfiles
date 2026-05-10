{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.program.app.notes;
in
{
  options.program.app.notes.enable = lib.mkEnableOption "Note-taking apps (Obsidian)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      obsidian
    ];
  };
}
