# VSCodium and its extensions. Settings are in
# home/.config/VSCodium/User/settings.json; `theme` adds the colors of the
# current theme there.
{pkgs, ...}: let
  market = pkgs.vscode-marketplace;
  universal = pkgs.vscode-marketplace-universal;
  openvsx = pkgs.open-vsx-release;

  extensions =
    (with market; [
      # editor
      editorconfig.editorconfig
      usernamehw.errorlens
      eamodio.gitlens
      streetsidesoftware.code-spell-checker
      christian-kohler.path-intellisense
      mkhl.direnv
      pkief.material-icon-theme
      moonbloom.moonbloom-theme
      adpyke.codesnap
      supermaven.supermaven
      wakatime.vscode-wakatime
      cantonios.project-templates
      tomoki1207.pdf

      # web
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      vue.volar
      nuxtr.nuxtr-vscode
      bradlc.vscode-tailwindcss
      antfu.goto-alias
      mikestead.dotenv
      bmewburn.vscode-intelephense-client

      # python
      ms-python.python
      ms-python.debugpy
      detachhead.basedpyright

      # systems languages
      golang.go
      rust-lang.rust-analyzer
      llvm-vs-code-extensions.vscode-clangd
      ms-vscode.cmake-tools
      gleam.gleam

      # java
      redhat.java
      vscjava.vscode-java-debug
      vscjava.vscode-java-test
      vscjava.vscode-maven
      vscjava.vscode-gradle

      # qt / qml
      theqtcompany.qt-core
      theqtcompany.qt-cpp
      theqtcompany.qt-qml
      theqtcompany.qt-ui

      # config, scripting and docs
      jnoortheen.nix-ide
      sumneko.lua
      mads-hartmann.bash-ide-vscode
      timonwong.shellcheck
      foxundermoon.shell-format
      redhat.vscode-yaml
      redhat.vscode-xml
      tamasfe.even-better-toml
      nefrob.vscode-just-syntax
      mechatroner.rainbow-csv
      davidanson.vscode-markdownlint
      bierner.markdown-mermaid

      # infrastructure and data
      ms-kubernetes-tools.vscode-kubernetes-tools
      ms-azuretools.vscode-docker
      dbdiagram.dbdiagram-vscode
      cweijan.vscode-database-client2
    ])
    ++ [
      universal.vadimcn.vscode-lldb
      universal.jgclark.vscode-todo-highlight
      universal.biomejs.biome
      openvsx.webfreak.code-d
      openvsx.charliermarsh.ruff
    ];
in {
  hjem.users.lex.packages = [
    (pkgs.vscode-with-extensions.override {
      vscode = pkgs.vscodium;
      vscodeExtensions = extensions;
    })
  ];
}
