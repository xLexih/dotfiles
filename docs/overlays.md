# Overlays

Plain overlay files in this directory are imported automatically by
`overlay/default.nix`. Add a new `*.nix` file that returns a normal Nixpkgs
overlay:

```nix
final: prev: {
  package-name = prev.package-name.overrideAttrs (old: {
    # patch, wrap, or replace while keeping the package name stable
  });
}
```

`overlay/default.nix` imports every top-level `*.nix` except `default.nix`
and `codium.nix`, sorted. The flake `overlay-registry-contract` asserts the
set is non-empty and that `codium.nix` never leaks into the auto-discovered
set.

Parameterized overlays stay explicit. `codium.nix` needs the active theme, so
`theme/module.nix` imports it directly after the theme is resolved.

OMP provider extensions share one helper in `overlay/omp.nix`
(`mkOmpExtension`); each provider is a name, version, description, and
homepage. Versions are read back from the derivations by
`user/lex/default.nix` to generate the plugin lock and symlinks, so a
version is written exactly once.
