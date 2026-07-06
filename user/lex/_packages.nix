{pkgs}: let
  inherit
    (pkgs)
    alacritty
    alejandra
    android-tools
    ani-cli
    atuin
    cilium-cli
    clang
    clang-tools
    claude-code
    cmake
    codex
    codium-custom
    delta
    delve
    devspace
    dig
    direnv
    fastfetch
    fzf
    gcc
    gdb
    gimp
    gnumake
    go
    go-tools
    gopls
    gradle
    hid-send
    inkscape
    jdk
    jq
    k9s
    kilo
    kitty
    krita-custom
    kubectl
    kubernetes-helm
    lazygit
    lutris-custom
    maven
    mirrord
    mold
    mtr
    mysql-workbench
    nautilus
    nettools
    nh
    nil
    ninja
    nix-direnv
    nix-tree
    nixd
    nodejs
    obsidian
    office-suite
    opencode
    openssh
    pkg-config
    powertop
    prismlauncher
    pwvucontrol
    quickshell
    tcpdump
    traceroute
    tree
    vesktop
    vlc
    yarn
    ;

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
    openssh
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
    codex
    codium-custom
    kilo
    opencode
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
    dig
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
    pkgs.qt6.qtbase
    pkgs.qt6.qtdeclarative
  ];

  goToolchain = [
    go
    gopls
    go-tools
    delve
  ];

  java = [
    jdk
    pkgs.jetbrains.jdk
    pkgs.jetbrains.jdk-21
    pkgs.jetbrains.idea
    maven
    gradle
  ];

  javascript = [
    nodejs
    yarn
  ];

  python = [
    pkgs.python3
  ];

  sql = [
    mysql-workbench
  ];
in {
  inherit
    browsersAndCommunication
    cpp
    development
    gaming
    goToolchain
    java
    javascript
    kubernetes
    media
    networkingAndDiagnostics
    notesAndOffice
    python
    sql
    terminalsAndUtilities
    ;

  all =
    terminalsAndUtilities
    ++ browsersAndCommunication
    ++ media
    ++ notesAndOffice
    ++ development
    ++ kubernetes
    ++ networkingAndDiagnostics
    ++ gaming
    ++ cpp
    ++ goToolchain
    ++ java
    ++ javascript
    ++ python
    ++ sql;
}
