final: prev: let
  mkOmpExtension = {
    pname,
    version,
    description,
    homepage ? null,
  }:
    prev.stdenvNoCC.mkDerivation {
      inherit pname version;
      src = ./omp/${prev.lib.removePrefix "omp-" pname};
      nativeCheckInputs = [prev.bun];
      doCheck = true;
      checkPhase = ''
        runHook preCheck
        if [ -d test ]; then
          bun test test
        fi
        runHook postCheck
      '';
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib/${pname}"
        cp package.json "$out/lib/${pname}/"
        cp -r src "$out/lib/${pname}/"
        runHook postInstall
      '';
      passthru.extensionPath = "lib/${pname}/src/index.ts";
      meta =
        {
          inherit description;
          platforms = prev.lib.platforms.all;
        }
        // prev.lib.optionalAttrs (homepage != null) {inherit homepage;};
    };
in {
  omp-provider-surplus = mkOmpExtension {
    pname = "omp-provider-surplus";
    version = "0.8.2";
    description = "Surplus Intelligence provider extension for Oh My Pi";
    homepage = "https://www.surplusintelligence.ai";
  };

  omp-time-manager = mkOmpExtension {
    pname = "omp-time-manager";
    version = "0.1.3";
    description = "Prompt and model-call duration status for Oh My Pi";
  };

  omp-provider-openbroker = mkOmpExtension {
    pname = "omp-provider-openbroker";
    version = "0.8.0";
    description = "OpenBroker Gonka inference provider extension for Oh My Pi";
    homepage = "https://openbroker.gonka.gg";
  };

  omp-provider-tokenrouter = mkOmpExtension {
    pname = "omp-provider-tokenrouter";
    version = "0.1.0";
    description = "TokenRouter OpenAI-compatible provider extension for Oh My Pi";
    homepage = "https://www.tokenrouter.com";
  };

  omp-provider-cline = mkOmpExtension {
    pname = "omp-provider-cline";
    version = "0.1.0";
    description = "Cline OpenAI-compatible provider extension for Oh My Pi";
    homepage = "https://app.cline.bot";
  };

  omp-provider-opencode-free = mkOmpExtension {
    pname = "omp-provider-opencode-free";
    version = "0.1.0";
    description = "OpenCode Zen free-models provider extension for Oh My Pi";
    homepage = "https://opencode.ai/docs/zen";
  };

  omp-provider-zen-router = mkOmpExtension {
    pname = "omp-provider-zen-router";
    version = "0.1.0";
    description = "Local Zen key-pool router provider extension for Oh My Pi";
  };
  omp-provider-glm = mkOmpExtension {
    pname = "omp-provider-glm";
    version = "0.1.0";
    description = "Local GLM bridge (Z.AI proxy API) provider extension for Oh My Pi";
  };
}
