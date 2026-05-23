{theme}: final: prev: let
  codium = final.vscodium.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final.makeWrapper];
    postInstall =
      (old.postInstall or "")
      + ''
        ln -s $out/lib/vscode/bin/codium-tunnel $out/lib/vscode/bin/code-tunnel
        wrapProgram $out/bin/codium \
          --prefix LD_LIBRARY_PATH : "${final.lib.makeLibraryPath [final.stdenv.cc.cc.lib]}"
      '';
  });

  themeExtension = theme.outputs.codium or null;
  themeFile =
    if themeExtension == null
    then null
    else final.writeText themeExtension.themeFileName themeExtension.themeJson;

  themedExtension =
    if themeExtension == null
    then null
    else
      final.stdenv.mkDerivation {
        pname = themeExtension.packageName;
        version = themeExtension.version;
        dontUnpack = true;
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          dir="$out/share/vscode/extensions/${themeExtension.uniqueId}"
          mkdir -p "$dir/themes"
          cp ${themeExtension.manifestPath} "$dir/package.json"
          cp ${themeFile} "$dir/themes/${themeExtension.themeFileName}"
          runHook postInstall
        '';
        passthru = {
          vscodeExtPublisher = themeExtension.publisher;
          vscodeExtName = themeExtension.name;
          vscodeExtUniqueId = themeExtension.uniqueId;
        };
      };

  extensions = let
    mkt = final.vscode-marketplace;
    uni = final.vscode-marketplace-universal;
    osx = final.open-vsx-release;
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

      supermaven.supermaven
      dbdiagram.dbdiagram-vscode
      tomoki1207.pdf
      wakatime.vscode-wakatime
      cantonios.project-templates

      cweijan.vscode-database-client2
    ])
    ++ [uni.vadimcn.vscode-lldb]
    ++ final.lib.optional (themedExtension != null) themedExtension
    ++ (with osx; [
      webfreak.code-d
    ]);
in {
  codium-custom = final.vscode-with-extensions.override {
    vscode = codium;
    vscodeExtensions = extensions;
  };
}
