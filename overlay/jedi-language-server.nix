final: prev: let
  packageOverrides = pyFinal: pyPrev: {
    jedi-language-server = pyPrev.jedi-language-server.overridePythonAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pyFinal.pythonRelaxDepsHook];
      pythonRelaxDeps = (old.pythonRelaxDeps or []) ++ ["jedi"];
    });
  };

  python3 = prev.python3.override {
    self = python3;
    packageOverrides = prev.lib.composeExtensions (prev.python3.packageOverrides or (_: _: {})) packageOverrides;
  };
in {
  inherit python3;
  python3Packages = python3.pkgs;
}
