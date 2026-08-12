final: prev: {
  omp-provider-surplus = prev.stdenvNoCC.mkDerivation {
    pname = "omp-provider-surplus";
    version = "0.2.0";
    src = ./omp-provider-surplus;

    nativeCheckInputs = [prev.bun];
    doCheck = true;

    checkPhase = ''
      runHook preCheck
      bun test test
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/omp-provider-surplus"
      cp package.json "$out/lib/omp-provider-surplus/"
      cp -r src "$out/lib/omp-provider-surplus/"
      runHook postInstall
    '';

    passthru.extensionPath = "lib/omp-provider-surplus/src/index.ts";

    meta = {
      description = "Surplus Intelligence provider extension for Oh My Pi";
      homepage = "https://www.surplusintelligence.ai";
      platforms = prev.lib.platforms.all;
    };
  };
}
