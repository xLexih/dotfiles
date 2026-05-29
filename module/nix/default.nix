{inputs, ...}: {
  environment.etc."nix/inputs/nixpkgs".source = inputs.nixpkgs;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
      max-jobs = "auto";
      cores = 0;
      use-xdg-base-directories = true; # respect xdg dirs
      download-buffer-size = 524288000; # workaround for nix#11728
      trusted-users = ["root" "@wheel"];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true; # run missed gc after sleep
    };
  };

  programs.nix-index-database.comma.enable = true;
  programs.nix-ld.enable = true;
}
