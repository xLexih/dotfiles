final: prev:
# Override `omp` (oh-my-pi) with the v18.0.8 prebuilt release binary.
#
# Upstream numtide/llm-agents.nix pins omp at 18.0.6, but v18.0.7+ contain a
# critical fix for the agent retry/compaction wedge:
#
#   PR #9530 (commits 39ce9b85bc + 7b185d1) — "fix(agent): resumed maintenance
#   after speculative handoff". Without it, `AgentSession.#processAgentEvent`
#   skipped post-turn maintenance while a speculative handoff was running, so a
#   `length`-stopped turn plus a `lastRole: custom` compaction-miss would loop
#   the agent in a tight retry storm (identical request → identical truncated
#   response → identical retry) with no path to recovery.
#
# Rather than rebuild the Rust + Bun toolchain from source, use the canonical
# prebuilt release asset the upstream install script uses
# (scripts/install.sh downloads `omp-linux-x64`). The binary is a single
# dynamically-linked ELF that only requires glibc, which is already in the
# store; `autoPatchelfHook` rewrites the RPATH to the nix-store glibc.
{
  omp = prev.stdenvNoCC.mkDerivation {
    pname = "omp";
    version = "18.0.8";
    src = prev.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v18.0.8/omp-linux-x64";
      hash = "sha256-sVxxYqPMdImMKs52UkFYpKJOQ/nQhlAefacanzoYX4A=";
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
