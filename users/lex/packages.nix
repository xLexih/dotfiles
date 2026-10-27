{
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit (config.modules.hardware.graphics.nvidia) offload;
in {
  hjem.users.lex.packages = with pkgs; [
    # terminal and shell
    atuin
    delta
    direnv
    fastfetch
    fzf
    jq
    kitty
    lazygit
    nautilus
    nix-direnv
    tree

    # nix
    alejandra
    nil
    nixd
    nix-tree

    # desktop apps
    gimp
    inkscape
    krita-custom
    libreoffice-qt-stable
    obsidian
    onlyoffice-desktopeditors
    pwvucontrol
    vesktop
    inputs.ayugram-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    vlc

    # agents
    llm-agents.claude-code
    llm-agents.codex
    llm-agents.kilocode-cli
    llm-agents.opencode
    pi-coding-agent

    # development
    android-tools
    ani-cli
    git-private
    hid-send

    # kubernetes
    cilium-cli
    devspace
    k9s
    kubectl
    kubernetes-helm
    mirrord

    # networking and diagnostics
    dig
    mtr
    nettools
    powertop
    tcpdump
    traceroute

    # gaming, on the NVIDIA GPU
    (offload lutris-custom)
    (offload prismlauncher)

    # c / c++ / qt
    bear
    clang
    clang-tools
    cmake
    gcc
    gdb
    gnumake
    lldb
    mold
    ninja
    pkg-config
    qt6.qtbase
    qt6.qtdeclarative

    # go
    delve
    go
    go-tools
    gopls

    # java
    gradle
    jdk
    jetbrains.idea
    jetbrains.jdk
    jetbrains.jdk-21
    maven

    # javascript
    nodejs
    yarn

    # python
    python3
    ruff

    # lua, shell, php: language servers and tools used by VSCodium
    bash-language-server
    lua-language-server
    php
    shellcheck
    shfmt
  ];
}
