final: prev: {
  omp-provider-surplus = prev.stdenvNoCC.mkDerivation {
    pname = "omp-provider-surplus";
    version = "0.8.2";
    src = ./omp/provider-surplus;

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

  omp-time-manager = prev.stdenvNoCC.mkDerivation {
    pname = "omp-time-manager";
    version = "0.1.3";
    src = ./omp/time-manager;

    nativeCheckInputs = [prev.bun];
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      bun test test
      runHook postCheck
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/omp-time-manager"
      cp package.json "$out/lib/omp-time-manager/"
      cp -r src "$out/lib/omp-time-manager/"
      runHook postInstall
    '';

    passthru.extensionPath = "lib/omp-time-manager/src/index.ts";
    meta = {
      description = "Prompt and model-call duration status for Oh My Pi";
      platforms = prev.lib.platforms.all;
    };
  };

  omp-provider-openbroker = prev.stdenvNoCC.mkDerivation {
    pname = "omp-provider-openbroker";
    version = "0.6.0";
    src = ./omp/provider-openbroker;

    nativeCheckInputs = [prev.bun];
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      bun test test
      runHook postCheck
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/omp-provider-openbroker"
      cp package.json "$out/lib/omp-provider-openbroker/"
      cp -r src "$out/lib/omp-provider-openbroker/"
      runHook postInstall
    '';

    passthru.extensionPath = "lib/omp-provider-openbroker/src/index.ts";
    meta = {
      description = "OpenBroker Gonka inference provider extension for Oh My Pi";
      homepage = "https://openbroker.gonka.gg";
      platforms = prev.lib.platforms.all;
    };
  };
}
