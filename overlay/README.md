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

Parameterized overlays stay explicit. For example, `codium.nix` needs the active
theme, so `theme/module.nix` imports it directly after the theme is resolved.
