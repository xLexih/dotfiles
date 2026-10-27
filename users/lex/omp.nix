# Oh My Pi: the pinned binary from pkgs/omp, managed overlays, agent
# conventions, and every extension from pkgs/omp-extensions.
#
# omp-look.yml (appearance) and omp-behavior.yml (behaviour) are passed with
# --config, so their keys win over ~/.omp/agent/config.yml. That file is not
# deployed from the repo and holds only what the user owns by hand: model roles.
{
  lib,
  pkgs,
  ...
}: let
  omp =
    pkgs.runCommand "omp-${pkgs.omp.version}" {
      nativeBuildInputs = [pkgs.makeWrapper];
      meta.mainProgram = "omp";
    } ''
      # PI_CODING_AGENT_DIR points pi-coding-agent at ~/.config/pi/agent
      # (global/xdg.nix), but omp honours it too and would move its sessions,
      # credentials and memory there; unset it so omp stays in ~/.omp/agent.
      # LD_LIBRARY_PATH: the mnemopi embed worker dlopens the unpatched
      # onnxruntime binding from ~/.omp/cache at runtime, which needs libstdc++.
      makeWrapper ${lib.getExe pkgs.omp} $out/bin/omp \
        --add-flags "--config ${./omp-look.yml}" \
        --add-flags "--config ${./omp-behavior.yml}" \
        --unset PI_CODING_AGENT_DIR \
        --prefix LD_LIBRARY_PATH : ${lib.getLib pkgs.stdenv.cc.cc}/lib
    '';

  extensions = lib.attrValues (lib.filterAttrs (_: lib.isDerivation) pkgs.omp-extensions);
  agentsMd = builtins.readFile ./omp-agents.md;
in {
  hjem.users.lex = {
    packages = [omp];

    files =
      {
        ".omp/agent/AGENTS.md" = {
          type = "copy";
          text = agentsMd;
        };
        ".config/codex/AGENTS.md" = {
          type = "copy";
          text = agentsMd;
        };
        ".omp/plugins/omp-plugins.lock.json" = {
          type = "copy";
          text = builtins.toJSON {
            plugins = lib.listToAttrs (map (ext:
              lib.nameValuePair ext.pname {
                inherit (ext) version;
                enabled = true;
                enabledFeatures = null;
              })
            extensions);
            settings = {};
          };
        };
      }
      // lib.listToAttrs (map (ext:
        lib.nameValuePair ".omp/plugins/node_modules/${ext.pname}" {
          source = "${ext}/lib/${ext.pname}";
        })
      extensions);
  };
}
