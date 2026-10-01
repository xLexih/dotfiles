# Themes

```
theme/
  base/
    default.nix     finds the named themes, renders each into /etc/themes, the `theme` command
    options.nix     every value a theme can set, with defaults
    lib.nix         color helpers (hex, rgb, Qt formats)
    targets/        one file per program that gets themed
  hexagon.nix       named themes
  hexagon-light.nix
```

## Named themes

A named theme is a NixOS-style module evaluated against
`theme/base/options.nix`. Only `palette` is required:

```nix
# theme/mytheme.nix
{
  variant = "dark";
  palette = {
    bg = "#1a1024";
    bgDark = "#130c1b";
    bgDarker = "#0d0812";
    surface = "#251735";
    overlay = "#38274d";
    fg = "#eee6f8";
    fgMuted = "#b0a4c8";
    accent = "#c6a0ff";
    accentAlt = "#8bd5ca";
    accentBright = "#e2c7ff";
    shadow = "#08050d";
    red = "#f38ba8";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    blue = "#b4befe";
    cyan = "#94e2d5";
  };
}
```

The file name is the theme name. It's picked up by `theme list` and the gear
in the bar after the next rebuild, and is a valid `modules.theme.default`.
Colors are type-checked (`#rrggbb`), so a typo fails evaluation instead of
producing a broken config.

Everything else has a default derived from `palette` or `variant` and can be
overridden in the theme file:

| Option | Default |
| --- | --- |
| `variant` | `"dark"`; picks the dark or light GTK theme, Kvantum theme, KDE look and feel, and the dark/light preference reported to GTK, Firefox and VSCode |
| `roles.*` | what a color is used for: `selectionBg`, `border`, `focus`, `hoverBg`, `link`, ... |
| `terminal.*` | kitty and VSCode terminal colors, including `normal.*` and `bright.*` ANSI colors |
| `spicetify.*` | Spotify `color.ini` keys |
| `gtk`, `cursor` | adw-gtk3, Bibata-Modern-Classic 24 |
| `icons` | Papirus-Dark or Papirus-Light by `variant`, folders tinted to match `gnomeAccent` |
| `fonts` | Noto Sans 11, JetBrains Mono 11 |
| `qt.kvantum`, `qt.lookAndFeel`, `qt.colorScheme` | KvArc(Dark), Breeze (Dark), the capitalized theme name |
| `gnomeAccent` | `"blue"` |

To reference your own palette in an override, take `config`:

```nix
{config, ...}: {
  palette = { /* ... */ };
  terminal.cursor = config.palette.accent;
  roles.selectionFg = config.palette.bg;
}
```

`hexagon.nix` is a full example; `hexagon-light.nix` is the same idea with
`variant = "light"`.

## Switching

Every theme is rendered at build time into `/etc/themes/<name>/`: a
`theme.json` describing it and a `home/` tree of files. `theme set <name>`
(or `next`/`prev`, which the gear runs) copies that tree into `$HOME`, saves
the name in `~/.local/state/theme/name` and runs each target's reload hook.
The command also runs on login and after every rebuild (`theme apply`), so
the choice persists and edited theme files get reset like other dotfiles.

Theme files belong to the `theme` command. A `home/` dotfile at the same path
fails the build with an assertion.

## Targets

Each file in `theme/base/targets/` handles one program. A target can set:

- `modules.theme.render.<target> = theme: { "<path in $HOME>" = text; }`:
  files rendered for every theme.
- `modules.theme.reload.<target>`: shell run after a switch so running
  programs pick up the new files. `theme_get <jq filter>` reads the new
  `theme.json`; failures are ignored.
- `modules.theme.metadata.<key> = theme: value`: extra `theme.json` values for
  reload hooks.

| Target | Files | After a switch |
| --- | --- | --- |
| `gtk.nix` | GTK 3/4 `gtk.css` overriding libadwaita's named colors, `settings.ini`, `.gtkrc-2.0` | writes GTK theme, icons, cursor, fonts and dark/light to dconf; libadwaita, Firefox and Electron follow the preference live, CSS applies to newly started apps |
| `qt.nix` | qt5ct/qt6ct, Kvantum, kdeglobals, KDE color scheme | newly started Qt apps |
| `kitty.nix` | `~/.config/kitty/theme.conf` | every kitty window reloads |
| `hyprland.nix` | `~/.config/hypr/theme.lua` (borders, shadow, cursor), share-picker stylesheet | re-runs `theme.lua`, sets the cursor |
| `palette.nix` | `~/.config/theme/palette.json`, `palette.sh` | the bar watches the JSON; new shells source the script |
| `firefox.nix` | `~/.cache/wal/colors.json` | Pywalfox recolors Firefox through its theme API |
| `vscode.nix` | one extension with every theme (`modules.theme.vscodeExtension`) | sets `workbench.colorTheme` in VSCodium's settings |
| `swayosd.nix` | volume/brightness popup CSS | restarts the popup service |
| `satty.nix` | annotation palette and font | next screenshot |
| `spicetify/` | Spotify `color.ini` and `user.css` | nothing: Spicetify patches Spotify at build time, so Spotify keeps `modules.theme.default` |

Firefox uses [Pywalfox](https://github.com/Frewacom/pywalfox) (installed by
policy, with its native host): signed Firefox builds can't load a local
extension, and the theme API is the only way to recolor Firefox without a
restart. Pywalfox maps a 16-color pywal palette onto the browser theme, so
`firefox.nix` decides which theme colors land on the indices its dark and
light templates read.

Adding a program means adding one file to `targets/`. If the program needs a
color nobody has a name for yet, add a role or a target-specific option to
`options.nix` with a default derived from the palette, the way `spicetify.*`
does, so existing themes keep working without changes.
