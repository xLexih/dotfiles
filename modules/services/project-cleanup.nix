# Idle cleanup for direnv projects. An .envrc opts in with
# `cleanup_on_idle <delay> <command>` (global direnvrc); every 5 minutes
# `project-cleanup scan` runs the command of each project that no process has
# had its working directory in for <delay>. Nothing stays resident.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.project-cleanup;
in {
  options.modules.services.project-cleanup.enable = lib.mkEnableOption "idle cleanup of direnv projects (`project-cleanup`)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.project-cleanup];

    systemd.user.services.project-cleanup = {
      description = "Clean up idle direnv projects";
      # Cleanup commands need the user's tools (docker, nix, git), not the
      # minimal PATH NixOS gives units.
      environment.PATH = lib.mkForce "/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkgs.project-cleanup} scan";
        Nice = 10;
        IOSchedulingClass = "idle";
      };
    };

    systemd.user.timers.project-cleanup = {
      description = "Scan direnv projects for idle cleanup";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnStartupSec = "5min";
        # Counted from the end of the last run, so long cleanups never overlap.
        OnUnitInactiveSec = "5min";
        AccuracySec = "1min";
      };
    };
  };
}
