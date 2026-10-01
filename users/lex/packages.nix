{pkgs, ...}: {
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
    nh
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
    vlc
    zotero

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

    # gaming
    lutris-custom
    prismlauncher

    # c / c++ / qt
    clang
    clang-tools
    cmake
    gcc
    gdb
    gnumake
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
