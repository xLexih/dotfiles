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
`theme/programs/<program>.nix` and return the files it owns.

Files returned through `homeFiles`, `xdgConfigFiles`, and `xdgDataFiles` are
managed as generated theme files and clobber existing files by default. Set
`clobber = false` on a specific file only when the target must preserve local
manual edits.

Theme-specific values still live in `theme/<name>/default.nix` and generated
outputs still live under `theme/<name>/outputs.nix`. Hosts select a theme with
`modules.theme = { enable = true; name = "<name>"; };`. This keeps the shape of
a theme separate from the list of programs that consume it.
