# Theme Program Targets

Each file in this directory describes one program or toolkit surface that can be
generated from a theme. Program targets return any of these attrsets:

```nix
{
  homeFiles = {};
  xdgConfigFiles = {};
  xdgDataFiles = {};
  environmentEtc = {};
}
```

`theme/module.nix` imports this registry once for the active theme and merges the
target attrsets into `hjem` and `/etc`. To add a themed program, create
`theme/programs/<program>.nix`, return the files it owns, and add it to
`programs` in `theme/programs/default.nix`.

Theme-specific values still live in `theme/<name>/default.nix` and generated
outputs still live under `theme/<name>/outputs.nix`. This keeps the shape of a
theme separate from the list of programs that consume it.
