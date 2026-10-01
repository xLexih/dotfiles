# Oh My Pi from the upstream release binary. Pinned ahead of nixpkgs (18.1.21)
# and llm-agents (18.3.2); this replaces nixpkgs' `omp` for the whole system.
{
  autoPatchelfHook,
  fetchurl,
  glibc,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "omp";
  version = "18.4.3";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${finalAttrs.version}/omp-linux-x64";
    hash = "sha256-r87N/x9CHzyI+xcUxAezcAiZtN4+0APNg2n1KubKh94=";
  };

  dontUnpack = true;
  dontStrip = true;
  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [glibc];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/omp
    runHook postInstall
  '';

  meta = {
    description = "Terminal-based coding agent with multi-model support";
    homepage = "https://github.com/can1357/oh-my-pi";
    changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "omp";
    platforms = ["x86_64-linux"];
  };
})
