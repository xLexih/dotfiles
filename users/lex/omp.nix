# Oh My Pi: the pinned binary from pkgs/omp, the look in omp-look.yml and every
# extension from pkgs/omp-extensions.
#
# omp-look.yml is passed with --config, so its keys win over
# ~/.omp/agent/config.yml while that file stays writable for `omp config set`.
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
      makeWrapper ${lib.getExe pkgs.omp} $out/bin/omp --add-flags "--config ${./omp-look.yml}"
    '';

  extensions = lib.attrValues (lib.filterAttrs (_: lib.isDerivation) pkgs.omp-extensions);
in {
  hjem.users.lex = {
    packages = [omp];

    files =
      {
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
