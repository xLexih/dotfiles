{pkgs}: let
  groups = with pkgs; {
    terminalsAndUtilities = [
      kitty
      alacritty
      nautilus
      alejandra
      atuin
      delta
      direnv
      fzf
      lazygit
      nh
      nix-direnv
      quickshell
      hid-send
      nix-tree
      nil
      nixd
      fastfetch
      jq
      tree
    ];

    browsersAndCommunication = [
      vesktop
    ];

    media = [
      vlc
      pwvucontrol
      inkscape
      gimp
      krita-custom
    ];

    notesAndOffice = [
      obsidian
      office-suite
    ];

    development = [
      android-tools
      claude-code
      pkgs.llm-agents.codex
      codium-custom
      git-private
      kilo
      opencode
      pi-coding-agent
      ani-cli
    ];

    kubernetes = [
      k9s
      kubectl
      kubernetes-helm
      cilium-cli
      mirrord
      devspace
    ];

    networkingAndDiagnostics = [
      nettools
      tcpdump
      traceroute
      mtr
      powertop
    ];

    gaming = [
      prismlauncher
      lutris-custom
    ];

    cpp = [
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
      qt6.qtdeclarative
    ];

    goToolchain = [
      go
      gopls
      go-tools
      delve
    ];

    java = [
      jdk
      jetbrains.jdk
      jetbrains.jdk-21
      jetbrains.idea
      maven
      gradle
    ];

    javascript = [
      nodejs
      yarn
    ];

    python = [
      python3
    ];

    sql = [
      mysql-workbench
    ];
  };

  groupOrder = [
    "terminalsAndUtilities"
    "browsersAndCommunication"
    "media"
    "notesAndOffice"
    "development"
    "kubernetes"
    "networkingAndDiagnostics"
    "gaming"
    "cpp"
    "goToolchain"
    "java"
    "javascript"
    "python"
    "sql"
  ];
in
  groups
  // {
    all = builtins.concatLists (map (name: groups.${name}) groupOrder);
  }
