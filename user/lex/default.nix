{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.user.lex;
  activeTheme = config.modules.theme.active;
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
      };

      packages = with pkgs; [
        # terminals & utilities
        kitty
        alacritty
        nautilus
        alejandra
        direnv
        fzf
        hid-send
        nix-tree
        nil
        nixd
        fastfetch
        jq
        tree
        openssh

        # browsers & communication
        vesktop

        # media
        vlc
        pwvucontrol
        inkscape
        gimp
        krita-custom

        # notes & office
        obsidian
        office-suite

        # development
        android-tools
        claude-code
        codex
        codium-custom
        kilo
        opencode
        ani-cli

        # kubernetes
        k9s
        kubectl
        kubernetes-helm
        cilium-cli
        mirrord
        devspace

        # networking & diagnostics
        nettools
        tcpdump
        traceroute
        mtr
        dig
        powertop

        # gaming
        prismlauncher
        lutris-custom

        # remote
        rustdesk

        # C/C++
        gcc
        cmake
        gnumake
        ninja
        clang
        clang-tools
        gdb
        mold
        pkg-config
        qt6.qtbase

        # Go
        go
        gopls
        go-tools
        delve

        # Java
        jdk
        maven
        gradle

        # JavaScript / TypeScript
        nodejs
        yarn
        pnpm

        # Python
        python3

        # SQL
        mysql-workbench
      ];
    };

    fonts.packages = with pkgs; [
      corefonts # Microsoft core fonts
    ];

    modules.software.docker = {
      enable = true;
      nvidia.enable = true;
    };
    modules.software.netclient.enable = false;
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
      };
    };

    programs.firefox = {
      enable = true;
      package = pkgs.firefox;

      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        Preferences = {
          "svg.context-properties.content.enabled" = true;
          "layout.css.color-mix-multi-color.enabled" = true;
          "widget.wayland.fractional-scale.enabled" = false;
          "dom.ipc.processCount" = 4;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          "widget.dmabuf.force-enabled" = true;
          "ui.systemUsesDarkTheme" = true;
          "ui.highlight" = activeTheme.ui.accent;
          "ui.highlighttext" = activeTheme.ui.bg;
          "browser.aboutConfig.showWarning" = false;
          "widget.gtk.hide-pointer-while-typing.enabled" = false;
          "findbar.highlightAll" = true;
          "accessibility.force_disabled" = 1;
          "extensions.pocket.enabled" = false;
          "browser.vpn_promo.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.recommendationprovider" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "browser.tabs.closeWindowWithLastTab" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "browser.formfill.enable" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.tabs.min_inactive_duration_before_unload" = 150000;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 1048576;
          "browser.cache.memory.max_entry_size" = -1;
          "browser.cache.disk.enable" = false;
          "browser.cache.disk.smart_size.enabled" = false;
          "browser.urlbar.placeholderName" = "me";
          "keyword.enabled" = true;
          "browser.urlbar.suggest.history" = false;
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.recentsearches" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.suggest.trending" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.yelp" = false;
          "browser.urlbar.suggest.addons" = false;
          "browser.urlbar.trimURLs" = false;
        };
        ExtensionSettings = {
          "firefox@tampermonkey.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";
          };
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          "{ddc62400-f22d-4dd3-8b4a-05837de53c2e}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/read-aloud/latest.xpi";
          };
          "{3c078156-979c-498b-8990-85f7987dd929}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
          };
          "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
          };
          "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/user-agent-string-switcher/latest.xpi";
          };
          "{c2c003ee-bd69-42a2-b0e9-6f34222cb046}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/auto-tab-discard/latest.xpi";
          };
        };
      };
    };
    modules.theme.hexagon.enable = true;
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
  };
}
