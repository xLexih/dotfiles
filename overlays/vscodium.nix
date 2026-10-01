# VSCodium with a `code-tunnel` alias for remote tunnels, and libstdc++ on the
# library path for native binaries that extensions ship.
final: prev: {
  vscodium = prev.vscodium.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final.makeWrapper];
    postInstall =
      (old.postInstall or "")
      + ''
        ln -s $out/lib/vscode/bin/codium-tunnel $out/lib/vscode/bin/code-tunnel
        wrapProgram $out/bin/codium \
          --prefix LD_LIBRARY_PATH : "${final.lib.makeLibraryPath [final.stdenv.cc.cc.lib]}"
      '';
  });
}
