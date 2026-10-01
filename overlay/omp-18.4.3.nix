final: prev:
# Override `omp` (oh-my-pi) with the v18.4.3 prebuilt release binary.
#
# Upstream is moving fast; nixpkgs carries 18.1.21 and
# numtide/llm-agents.nix carries 18.3.2, so keep the explicit pin ahead of
# both. Re-evaluate when either overtakes the pin.
#
# Rather than rebuild the Rust + Bun toolchain from source, use the canonical
# prebuilt release asset the upstream install script uses
# (scripts/install.sh downloads `omp-linux-x64`). The binary is a single
# dynamically-linked ELF that only requires glibc, which is already in the
# store; `autoPatchelfHook` rewrites the RPATH to the nix-store glibc.
{
  omp = prev.stdenvNoCC.mkDerivation {
    pname = "omp";
    version = "18.4.3";
    src = prev.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v18.4.3/omp-linux-x64";
      hash = "sha256-r87N/x9CHzyI+xcUxAezcAiZtN4+0APNg2n1KubKh94=";
    };
    nativeBuildInputs = [prev.autoPatchelfHook];
    dontUnpack = true;
    buildInputs = [prev.glibc];
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/omp
      runHook postInstall
    '';
    passthru.category = "AI Coding Agents";
    meta = with prev.lib; {
      description = "Terminal-based coding agent with multi-model support";
      homepage = "https://github.com/can1357/oh-my-pi";
      changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
      license = licenses.mit;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "omp";
      platforms = ["x86_64-linux"];
    };
  };
}
