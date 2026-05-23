final: prev: {
  krita-custom = prev.symlinkJoin {
    name = "krita-custom";
    paths = [
      prev.krita
      prev.krita-plugin-gmic
    ];
    nativeBuildInputs = [prev.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/krita --set QT_SCALE_FACTOR 1.5
    '';
  };
}
