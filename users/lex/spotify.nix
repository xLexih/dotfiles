# Spotify with Spicetify. The theme is set by theme/base/targets/spicetify.
{
  inputs,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  programs.spicetify = {
    enable = true;
    alwaysEnableDevTools = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      copyToClipboard
      groupSession
      hidePodcasts
      shuffle
    ];
  };

  environment.systemPackages = [pkgs.spicetify-cli];
}
