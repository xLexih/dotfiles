# Every directory here is an Oh My Pi extension. Name, version and description
# come from its package.json; tests under test/ run during the build.
{
  bun,
  lib,
  stdenvNoCC,
}: let
  mkExtension = dir: let
    manifest = lib.importJSON (dir + "/package.json");
  in
    stdenvNoCC.mkDerivation {
      pname = manifest.name;
      inherit (manifest) version;
      src = dir;

      nativeCheckInputs = [bun];
      doCheck = builtins.pathExists (dir + "/test");
      checkPhase = ''
        runHook preCheck
        bun test test
        runHook postCheck
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib/${manifest.name}
        cp -r package.json src $out/lib/${manifest.name}/
        runHook postInstall
      '';

      meta =
        {
          inherit (manifest) description;
          platforms = lib.platforms.all;
        }
        // lib.optionalAttrs (manifest ? homepage) {inherit (manifest) homepage;};
    };

  dirs = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.));
in
  lib.recurseIntoAttrs (lib.listToAttrs (map (name: let
    extension = mkExtension (./. + "/${name}");
  in
    lib.nameValuePair extension.pname extension)
  dirs))
