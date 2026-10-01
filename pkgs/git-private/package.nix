# `git private`: create repositories from templates/git-private and dispatch
# to their scripts/private.
{
  coreutils,
  git,
  gnused,
  just,
  writeShellApplication,
}:
writeShellApplication {
  name = "git-private";
  runtimeInputs = [coreutils git gnused just];
  text = builtins.replaceStrings ["@template@"] ["${../../templates/git-private}"] (builtins.readFile ./git-private.sh);
}
