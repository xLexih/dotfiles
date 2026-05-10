{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optionals;

  cfg = config.program.app.codium;

  codium = pkgs.vscodium.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
    postInstall =
      (old.postInstall or "")
      + ''
        ln -s $out/lib/vscode/bin/codium-tunnel $out/lib/vscode/bin/code-tunnel
        wrapProgram $out/bin/codium \
          --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}"
      '';
  });

  extensions = let
    mkt = pkgs.vscode-marketplace;
    uni = pkgs.vscode-marketplace-universal;
    osx = pkgs.open-vsx-release;
  in
    (with mkt; [
      vue.volar

      editorconfig.editorconfig
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      usernamehw.errorlens
      eamodio.gitlens
      streetsidesoftware.code-spell-checker

      nuxtr.nuxtr-vscode
      bradlc.vscode-tailwindcss
      antfu.goto-alias
      christian-kohler.path-intellisense
      mikestead.dotenv

      ms-python.python
      ms-python.vscode-pylance
      ms-python.black-formatter
      ms-python.debugpy

      golang.go

      rust-lang.rust-analyzer

      llvm-vs-code-extensions.vscode-clangd
      ms-vscode.cmake-tools

      theqtcompany.qt-core
      theqtcompany.qt-cpp
      theqtcompany.qt-qml
      theqtcompany.qt-ui

      gleam.gleam
      jnoortheen.nix-ide

      ms-kubernetes-tools.vscode-kubernetes-tools
      ms-azuretools.vscode-docker
      redhat.vscode-yaml

      bierner.markdown-mermaid
      tamasfe.even-better-toml

      pkief.material-icon-theme
      moonbloom.moonbloom-theme
      wayou.vscode-todo-highlight
      adpyke.codesnap

      saoudrizwan.claude-dev
      supermaven.supermaven
      dbdiagram.dbdiagram-vscode
      tomoki1207.pdf
      wakatime.vscode-wakatime
      cantonios.project-templates

      cweijan.vscode-database-client2
    ])
    ++ [uni.vadimcn.vscode-lldb]
    ++ optionals cfg.codeium.enable (with mkt; [codeium.codeium])
    ++ (with osx; [
      webfreak.code-d
    ]);
in {
  options.program.app.codium = {
    enable = mkEnableOption "VSCodium with a extensions";
    codeium.enable = mkEnableOption "Codeium extension";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.vscode-with-extensions.override {
        vscode = codium;
        vscodeExtensions = extensions;
      })
    ];
  };
}
