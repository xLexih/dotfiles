{
  inputs,
  pkgs,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = import ../overlays inputs;
  };

  # Lets tooling (nixd, nix repl) resolve the exact nixpkgs this system uses.
  environment.etc."nix/inputs/nixpkgs".source = inputs.nixpkgs;

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      warn-dirty = false;
      use-xdg-base-directories = true;
      download-buffer-size = 524288000; # nix#11728
      max-jobs = "auto";
      trusted-users = ["root" "@wheel"];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cache.lantian.pub/lantian" # cachyos kernels
        "https://cache.numtide.com" # llm-agents
        "https://ayugram-desktop.cachix.org" # ayugram
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "ayugram-desktop.cachix.org-1:AZ5EqHrJsAKL5YkZYLPEsb1FdD9QlypUwQ0REcJftgA="
      ];
    };

    # `nix flake init` without -t uses templates#templates.default, which is
    # templates/project here. NixOS's templates: `-t nixos-templates#<name>`.
    registry = {
      templates.flake = inputs.self;
      nixos-templates.to = {
        type = "github";
        owner = "NixOS";
        repo = "templates";
      };
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
    };
  };

  programs.nix-index-database.comma.enable = true;

  # Runs unpatched binaries. The extra libraries cover the Chrome build that
  # omp's browser tool downloads to ~/.cache/omp/puppeteer.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      mesa
      nspr
      nss
      pango
    ];
  };
}
