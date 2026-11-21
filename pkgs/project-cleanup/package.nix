# `project-cleanup`: runs a direnv project's cleanup command once no process
# has its working directory inside it. See modules/services/project-cleanup.nix.
{
  bash,
  coreutils,
  direnv,
  findutils,
  jq,
  libnotify,
  systemd,
  util-linux,
  writeShellApplication,
}:
writeShellApplication {
  name = "project-cleanup";
  runtimeInputs = [bash coreutils direnv findutils jq libnotify systemd util-linux];
  text = builtins.readFile ./project-cleanup.sh;
}
