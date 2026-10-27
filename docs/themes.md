# Themes

```
theme/
  base/
    default.nix     finds the named themes, renders each into /etc/themes, builds the `theme` command and its check
    theme.sh        the `theme` command
    options.nix     every value a theme can set, with defaults
    lib.nix         color, name and font helpers
    dynamic.nix     template and scheme mapping of the wallpaper-derived theme
    targets/        one file or directory per program that gets themed
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
| `terminal.*` | kitty and VSCode terminal colors, including `normal.*` and `bright.*` ANSI colors: `accent` cursor, `overlay` selection, `surface` inactive tabs; on light themes ANSI black and bright white are `fg`. Shell prompts use ANSI colors (magenta, green, bright black/magenta), so open terminals recolor on a switch |
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

Targets read `colors` (`palette` and `roles` merged) and `label` (the title-
cased name); both are derived and can't be set.

`hexagon.nix` is a full example; `hexagon-light.nix` is the same idea with
`variant = "light"`.

## Switching

Every theme is rendered at build time into `/etc/themes/<name>/`: a
`theme.json` describing it (name, label, variant, colors, terminal, fonts,
cursor and target metadata) and a `home/` tree of files. `theme set <name>`
(or `next`/`prev`, which the gear runs) copies that tree and `theme.json`
(to `~/.config/theme/theme.json`) into `$HOME`, deletes files the previous
theme installed that this one doesn't, saves the name in
`~/.local/state/theme/name` and runs each target's reload hook.
After every rebuild a `theme-<user>` service re-applies each user's choice
once hjem has updated the dotfiles, so it persists and edited theme files get
reset like other dotfiles. Hyprland runs `theme reload` (the hooks only) at
login. Rendered files can use `@HOME@` for the user's home directory.

Theme files belong to the `theme` command. A `home/` dotfile at the same path
fails the build with an assertion.

The system build runs `theme-check` (`system.checks`): it switches through
every theme and the dynamic one (from a dark and a light test image) in an
empty home, and fails if a placeholder survives, `theme.json` names the wrong
theme, or switching back leaves files behind.

## Dynamic theme

`dynamic` derives its palette from the wallpaper (`theme wallpaper <image>`
sets it through awww and remembers it). `dynamic.nix` is rendered like a
named theme, once dark and once light, with a sentinel color in each palette
slot (`#e1e210` to `#e1e21f`). On a switch, `theme`:

1. runs [matugen](https://github.com/InioX/matugen) on the wallpaper for a
   Material You scheme. It picks dark or light from the image and harmonizes
   the default theme's green, yellow, blue and cyan toward the wallpaper,
   since Material has no such colors.
2. maps scheme roles onto the palette (`roles` in `dynamic.nix`: surfaces to
   `bg`/`surface`, `primary` to `accent`, `tertiary` to `accentAlt`, ...).
3. copies the matching template to `~/.cache/theme/dynamic` and replaces each
   sentinel in every format targets write it (`#rrggbb`, `rrggbb`, `r,g,b`,
   `r;g;b`), then fails if any sentinel is left.
4. picks the closest GNOME accent by hue and applies the result like any
   other theme.

Because roles, terminal colors and every target derive from the palette,
targets need nothing extra to support it, as long as they only reformat
palette colors. A target that computes new colors (mixing, lightening) has
to do it at runtime (CSS `color-mix()`, `alpha()`) instead.

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
| `gtk.nix` | GTK 3/4 `gtk.css` overriding libadwaita's named colors, `settings.ini`, `~/.config/gtk-2.0/gtkrc` (via `GTK2_RC_FILES`) | writes GTK theme, icons, cursor, fonts and dark/light to dconf; libadwaita, Firefox and Electron follow the preference live, CSS applies to newly started apps |
| `qt.nix` | qt5ct/qt6ct, Kvantum, kdeglobals, KDE color scheme | newly started Qt apps |
| `kitty.nix` | `~/.config/kitty/theme.conf` | every kitty window reloads |
| `hyprland.nix` | `~/.config/hypr/theme.lua` (borders, shadow, cursor), share-picker stylesheet | re-runs `theme.lua`, sets the cursor |
| `palette.nix` | `~/.config/theme/palette.sh` | new shells source it; the bar watches `theme.json` |
| `man.nix` | `~/.config/theme/man.sh` (`less` `TERMCAP` colors for `man`) | new shells source it |
| `firefox/` | `~/.config/theme/firefox.css` | Firefox reloads it within 250 ms |
| `vscode.nix` | colors and token rules in `theme.json` | writes them to VSCodium's `settings.json` as color customizations over Default Dark/Light Modern |
| `swayosd/` | popup style sheet | restarts the popup service |
| `satty.nix` | annotation palette and font | next screenshot |
| `spicetify/` | Spotify `color.ini` and `user.css` | nothing: Spicetify patches Spotify at build time, so Spotify keeps `modules.theme.default` |

Where a program reads a real style sheet, the rules live in a static file
(`firefox/theme.css`, `swayosd/style.css`) that uses variables, and the
target only writes the theme's colors above it (`cssVariables` and
`gtkColors` in `lib.nix`). The sheet stays readable as CSS, and every theme,
the dynamic one included, shares it.

Firefox only reads `userChrome.css` and `userContent.css` at startup, and a
custom WebExtension theme would need Mozilla's signature. Instead an
AutoConfig script (`firefox/default.nix`, run by Firefox at startup with
full privileges) registers `~/.config/theme/firefox.css` as a user style
sheet, checks the file every 250 ms and swaps the sheet when `theme`
replaces it. One sheet covers the browser window, menus and panels, `about:`
pages and Sidebery, scoped with `@-moz-document`.
The script itself only runs at startup: after a rebuild that changes it,
quit Firefox completely (Ctrl+Q) and start it again. Opening a new window
while an old Firefox is still running reuses the old process.

Adding a program means adding one file to `targets/`. If the program needs a
color nobody has a name for yet, add a role or a target-specific option to
`options.nix` with a default derived from the palette, the way `spicetify.*`
does, so existing themes keep working without changes.
