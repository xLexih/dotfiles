# Oh My Pi from the upstream release binary; this replaces nixpkgs' `omp`
# for the whole system.
{
  autoPatchelfHook,
  fetchurl,
  glibc,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "omp";
  version = "19.0.0";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${finalAttrs.version}/omp-linux-x64";
    hash = "sha256-x8xcjVBQU8j/rxgEF+XVx4EjW52TbyhoEFYBURIBCb8=";
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
