# Dotfiles

A file at `global/home/.config/kitty/kitty.conf` ends up at
`~/.config/kitty/kitty.conf`, copied by [hjem](https://github.com/feel-co/hjem).
The same relative path can exist in three layers, merged from least to most
specific:

```
generated (dotfiles.files)  ->  global/home  ->  hosts/<host>/home  ->  users/<user>/home
```

- Text files (`.conf`, `.lua`, `.css`, `.ini`, shell files, ...) are
  concatenated. The global `hyprland.lua` defines `mainMod`, the host layer
  adds monitors, the user layer adds autostart and binds.
- `.json` files are merged key by key: a more specific layer only needs the
  keys it changes (nested objects merge too, lists are replaced). A host could
  ship `hosts/laptop/home/.config/VSCodium/User/settings.json` containing just
  `{"window.zoomLevel": 1}`.
- `.jsonc`, `.yaml`, `.yml`, `.toml`, `.qml`, `qmldir` and `.svg` can't be
  combined, so the most specific layer wins.
- Images and fonts are copied unchanged.

Files are copied rather than symlinked, so programs can write to them. Every
rebuild resets them to what the repo says; files that support comments get a
first line saying so. Port changes you want to keep back into the repo.

Modules can generate files too (`dotfiles.files`, e.g. Hyprland's portal
config). Those are the lowest layer, so a `home/` file at the same path
appends to them or replaces them. Theme files (kitty colors, GTK CSS, ...)
are not dotfiles: the `theme` command owns them, see [themes.md](themes.md).

## Placeholders

Layered files can use `{{name}}`, filled in at build time:

| Placeholder | Value |
| --- | --- |
| `{{qml.importPaths}}` | Quickshell's QML import paths, for qmllint |
| `{{pkgs.<attr>}}` | store path of a package, e.g. `{{pkgs.nix-direnv}}` |
| `{{host}}`, `{{flake}}` | host name, store path of this flake |

An unknown placeholder fails the build with the file name, so typos don't ship.
Modules add their own with `dotfiles.vars."name" = "value";`.
