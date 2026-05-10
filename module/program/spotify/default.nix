{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.program.app.spotify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    inputs.spicetify-nix.nixosModules.spicetify
  ];

  options.program.app.spotify.enable = lib.mkEnableOption "Spotify with Spicetify";

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        groupSession
        copyToClipboard
        betterGenres
        shuffle
      ];
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
    };
  };
}
