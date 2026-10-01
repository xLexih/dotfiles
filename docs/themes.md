# Themes

```
theme/
  base/
    default.nix     finds the named themes, resolves the selected one, theme-switch
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

The file name is the theme name, and it shows up as a valid value of
`modules.theme.name` right away. Colors are type-checked (`#rrggbb`), so a typo
fails evaluation instead of producing a broken config.

Everything else has a default derived from `palette` or `variant` and can be
overridden in the theme file:

| Option | Default |
| --- | --- |
| `variant` | `"dark"`; picks the dark or light GTK theme, Kvantum theme, KDE look and feel, and the dark/light preference reported to GTK, Firefox and VSCode |
| `roles.*` | what a color is used for: `selectionBg`, `border`, `focus`, `hoverBg`, `link`, ... |
| `terminal.*` | kitty and VSCode terminal colors, including `normal.*` and `bright.*` ANSI colors |
| `spicetify.*` | Spotify `color.ini` keys |
| `gtk`, `icons`, `cursor` | adw-gtk3, Adwaita, Bibata-Modern-Classic 24 |
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

## Targets

Each file in `theme/base/targets/` reads `config.modules.theme.active` and
applies it to one program:

| Target | Output |
| --- | --- |
| `gtk.nix` | GTK 2/3/4 settings and CSS, dconf interface settings, cursor variables |
| `qt.nix` | qt5ct/qt6ct, Kvantum, kdeglobals, KDE color scheme |
| `kitty.nix` | `~/.config/kitty/theme.conf`, also swappable with `theme-switch` |
| `firefox.nix` | profile, `userChrome.css`, `userContent.css` (including Sidebery), theme prefs |
| `vscode.nix` | a VSCode color theme extension, `modules.theme.vscodeExtension` |
| `spicetify/` | Spotify `color.ini` and `user.css` |
| `hyprland.nix` | themed screen-share picker |
| `palette.nix` | `~/.config/theme/palette.json` and `palette.sh` for scripts |

Generated home files go into `dotfiles.files`, which is the lowest dotfile
layer, so a user can extend them from their `home/` directory. Programs
configured by hand-written files (Hyprland, Quickshell) read colors through
`{{theme.*}}` placeholders instead; see the README.

Adding a program means adding one file to `targets/`. If the program needs a
color nobody has a name for yet, add a role or a target-specific option to
`options.nix` with a default derived from the palette, the way `spicetify.*`
does, so existing themes keep working without changes.
