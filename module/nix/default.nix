{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.nix;
in {
  options.modules.nix.permittedInsecurePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "pnpm-10.29.2"
      "electron-40.10.5"
    ];
    description = "Insecure nixpkgs packages allowed for this system.";
  };

  config = {
    environment.etc."nix/inputs/nixpkgs".source = inputs.nixpkgs;

    nixpkgs.config.permittedInsecurePackages = cfg.permittedInsecurePackages;

    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes"];
        warn-dirty = false;
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://attic.xuyh0120.win/lantian"
          "https://cache.numtide.com"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
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
    # Runtime closure for unpatched third-party Chrome binaries — notably the
    # stock Puppeteer Chrome omp downloads to ~/.omp/puppeteer and spawns as
    # the omp.browser.headless / omp.browser.headed daemons. Without these,
    # the loader fails on libglib etc. and both daemons die with exit 127.
    # (Merges with the nixpkgs nix-ld defaults; list options concatenate.)
    programs.nix-ld.libraries = with pkgs; [
      alsa-lib
      atk
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      libgbm
      mesa
      nspr
      nss
      pango
      libxkbcommon
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
    ];
  };
}
