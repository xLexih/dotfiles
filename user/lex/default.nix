{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.user.lex;
  activeTheme = config.modules.theme.active;
  lexPackages = import ./lib/packages.nix {inherit pkgs;};
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    inputs.spicetify-nix.nixosModules.spicetify
  ];

  options.modules.user.lex = {
    enable = lib.mkEnableOption "user lex";
  };

  config = lib.mkIf cfg.enable {
    users.users.lex = {
      isNormalUser = true;
      extraGroups = ["wheel" "video" "audio" "networkmanager" "docker" "libvirtd" "i2c" "plugdev"];
    };

    hjem.users.lex = {
      files = {
        ".local/share/lutris/runners/proton/GE-Proton".source = pkgs.proton-ge-bin.steamcompattool;
        ".omp/plugins/omp-plugins.lock.json" = {
          clobber = true;
          text = builtins.toJSON {
            plugins = {
              omp-provider-surplus = {
                version = "0.8.2";
                enabledFeatures = null;
                enabled = true;
              };
              omp-time-manager = {
                version = "0.1.3";
                enabledFeatures = null;
                enabled = true;
              };
              omp-provider-openbroker = {
                version = "0.6.0";
                enabledFeatures = null;
                enabled = true;
              };
            };
            settings = {};
          };
        };
        ".omp/plugins/node_modules/omp-provider-surplus".source = pkgs.omp-provider-surplus + "/lib/omp-provider-surplus";
        ".omp/plugins/node_modules/omp-time-manager".source = pkgs.omp-time-manager + "/lib/omp-time-manager";
        ".omp/plugins/node_modules/omp-provider-openbroker".source = pkgs.omp-provider-openbroker + "/lib/omp-provider-openbroker";
      };
      packages =
        lexPackages.all
        ++ [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
        ];
    };

    fonts.packages = with pkgs; [
      corefonts # Microsoft core fonts
    ];

    modules.software.docker = {
      enable = true;
      nvidia.enable = true;
    };
    modules.software.gaming.enable = true;
    modules.software.kdeconnect.enable = true;
    modules.software.obs.enable = true;
    modules.software.sunshine.enable = true;
    modules.software.virtual-machine.enable = true;
    modules.software.waydroid.enable = true;

    programs.git = {
      enable = true;
      config = {
        user.name = "lexih";
        user.email = "git@lexih.dev";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta.navigate = true;
        delta.side-by-side = true;
        merge.conflictstyle = "zdiff3";
        diff.colorMoved = "default";
        alias.private = "!git-private";
      };
    };

    programs.firefox = import ./lib/firefox.nix {inherit activeTheme pkgs;};
    programs.spicetify = {
      enable = true;
      alwaysEnableDevTools = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        groupSession
        copyToClipboard
        betterGenres
        shuffle
      ];
    };

    environment.systemPackages = [pkgs.spicetify-cli];
  };
}
