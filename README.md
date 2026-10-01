# dotfiles

NixOS flake for my machines. Each host is assembled from the same pieces:
global defaults, opt-in modules, the host's hardware, its users and a theme.
Dotfiles are plain files in `home/` directories, layered and copied into
`$HOME` by [hjem](https://github.com/feel-co/hjem).

```
flake.nix            hosts and the users on them, packages, checks
global/              applies to every host
  home/              global dotfile layer
hosts/<host>/        hardware, enabled modules
  home/              host dotfile layer (monitors, keybinds)
users/<user>/        account, packages, programs
  home/              user dotfile layer
modules/             opt-in NixOS modules (modules.*) and the dotfile layering
theme/
  base/              theme options, program targets, theme-switch
  <name>.nix         named themes
overlays/            changes to nixpkgs packages
pkgs/                packages defined here (pkgs/<name>/package.nix)
templates/           `nix flake init -t` templates
```

Everything under `global/`, `modules/`, `hosts/<host>/` and `users/<user>/`
is imported automatically, so a new `.nix` file there is picked up without
being listed anywhere. `home/` directories are skipped.

## Hosts and users

`flake.nix` lists the hosts and which users live on them:

```nix
nixosConfigurations = lib.mapAttrs mkHost {
  desktop.users = ["lex"];
  laptop.users = ["lex"];
};
```

A host turns modules on in `hosts/<host>/default.nix`
(`modules.desktop.hyprland.enable`, `modules.theme.name`, ...). A user can do
the same for things that follow the person rather than the machine, such as
`modules.software.gaming.enable` in `users/lex/default.nix`.

## Dotfiles

A file at `global/home/.config/kitty/kitty.conf` ends up at
`~/.config/kitty/kitty.conf`. The same relative path can exist in three
layers, merged from least to most specific:

```
theme output  ->  global/home  ->  hosts/<host>/home  ->  users/<user>/home
```

- Text files (`.conf`, `.lua`, `.css`, `.ini`, shell files, ...) are
  concatenated. The global `hyprland.lua` defines `mainMod`, the host layer
  adds monitors, the user layer adds autostart and binds.
- `.json`, `.jsonc`, `.yaml`, `.yml`, `.toml`, `.qml`, `.qmldir` and `.svg`
  can't be concatenated, so the most specific layer wins.
- Images and fonts are copied unchanged.

Files are copied rather than symlinked, so programs can write to them. Every
rebuild resets them to what the repo says; files that support comments get a
first line saying so. Port changes you want to keep back into the repo.

Theme targets generate some files (GTK CSS, Firefox `userChrome.css`, ...).
Those are the lowest layer: putting a file at the same path in a `home/`
directory appends to it (or replaces it, for the formats above). That is how
`users/lex/home/.mozilla/.../userChrome.css` hides the tab bar on top of the
themed Firefox.

### Placeholders

Layered files can use `{{name}}`, filled in at build time:

| Placeholder | Value |
| --- | --- |
| `{{theme.accent}}`, `{{theme.selectionBg}}`, ... | any palette or role color, `#rrggbb` |
| `{{theme.accent.hex}}` | the same color without `#` |
| `{{theme.cursor}}`, `{{theme.cursor.size}}`, `{{theme.gtk}}`, `{{theme.icons}}`, `{{theme.font.mono}}` | theme settings |
| `{{theme.vscode}}` | name of the generated VSCode color theme |
| `{{pkgs.<attr>}}` | store path of a package, e.g. `{{pkgs.nix-direnv}}` |
| `{{host}}`, `{{flake}}` | host name, store path of this flake |

An unknown placeholder fails the build with the file name, so typos don't ship.
Modules add their own with `dotfiles.vars."name" = "value";`.

## Themes

A named theme is a small file in `theme/` that sets colors; `theme/base`
turns them into program configuration. Pick one per host with
`modules.theme.name`. See [docs/themes.md](docs/themes.md).

`theme-switch <name>` swaps kitty's colors without rebuilding. The next
rebuild restores the configured theme.

## Packages

| Need | Where |
| --- | --- |
| A package from nixpkgs | `users/<user>/packages.nix` |
| A package that needs a NixOS service, group or kernel module | `modules/software/<name>.nix`, enabled from a host or user |
| A tweak to a nixpkgs package (wrapper, patch, override) | `overlays/<name>.nix`, a plain `final: prev:` overlay picked up automatically |
| A package that doesn't exist in nixpkgs | `pkgs/<name>/package.nix`, a `callPackage` function exposed as `pkgs.<name>` |

Packages in `pkgs/` are also flake outputs, so `nix build .#hid-send` works.
Every directory in `pkgs/omp-extensions/` is an Oh My Pi extension; its
`package.json` supplies name and version, and `users/lex/omp.nix` installs and
enables all of them.

## Commands

```bash
sudo nixos-rebuild switch --flake .#laptop   # or: nh os switch .
nix flake check                              # formatting, host evaluation, hyprland.lua syntax, package tests
nix fmt .                                    # alejandra
```
