# dotfiles

NixOS flake for my machines. Each host is assembled from the same pieces:
global defaults, opt-in modules, the host's hardware, its users and a theme.
Dotfiles are plain files in `home/` directories, layered and copied into
`$HOME` by [hjem](https://github.com/feel-co/hjem).

```
flake.nix            hosts and the users on them, packages, checks
global/              applies to every host
  home/              global dotfile layer
hosts/<host>/        hardware, enabled modules, specs.md (hardware inventory)
  home/              host dotfile layer (monitors, keybinds)
users/<user>/        account, packages, programs
  home/              user dotfile layer
modules/             opt-in NixOS modules (modules.*) and the dotfile layering
theme/
  base/              theme options, program targets, the `theme` command
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
(`modules.desktop.hyprland.enable`, `modules.theme.default`, ...). A user can do
the same for things that follow the person rather than the machine, such as
`modules.software.gaming.enable` in `users/lex/default.nix`.

## Dotfiles

A file at `global/home/.config/kitty/kitty.conf` ends up at
`~/.config/kitty/kitty.conf`. The same relative path can exist in three
layers, merged from least to most specific:

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
- `.jsonc`, `.yaml`, `.yml`, `.toml`, `.qml`, `.qmldir` and `.svg` can't be
  combined, so the most specific layer wins.
- Images and fonts are copied unchanged.

Files are copied rather than symlinked, so programs can write to them. Every
rebuild resets them to what the repo says; files that support comments get a
first line saying so. Port changes you want to keep back into the repo.

Modules can generate files too (`dotfiles.files`, e.g. Hyprland's portal
config). Those are the lowest layer, so a `home/` file at the same path
appends to them or replaces them. Theme files (kitty colors, GTK CSS, ...)
are not dotfiles: the `theme` command owns them, see below.

### Placeholders

Layered files can use `{{name}}`, filled in at build time:

| Placeholder | Value |
| --- | --- |
| `{{qml.importPaths}}` | Quickshell's QML import paths, for qmllint |
| `{{pkgs.<attr>}}` | store path of a package, e.g. `{{pkgs.nix-direnv}}` |
| `{{host}}`, `{{flake}}` | host name, store path of this flake |

An unknown placeholder fails the build with the file name, so typos don't ship.
Modules add their own with `dotfiles.vars."name" = "value";`.

## Themes

A named theme is a small file in `theme/` that sets colors; `theme/base`
turns them into program configuration. See [docs/themes.md](docs/themes.md).

Themes switch at runtime, without a rebuild: click the gear at the bottom of
the bar (right click goes back), or run `theme next`, `theme set <name>`,
`theme list`. Kitty, Hyprland borders, the bar, Firefox, VSCodium, the volume
popup and the GTK dark/light preference change right away; GTK and Qt colors
apply to apps started afterwards. The choice is kept per user across rebuilds;
`modules.theme.default` is the theme before anyone picks one.

`dynamic` takes its colors from the wallpaper: surfaces from its dominant
color, the accent from its most vivid one. Set one with
`theme wallpaper <image>` (SVG works too), or go back to one of Hyprland's
own with `theme wallpaper default`; from then on `dynamic` joins the cycle,
and while it's active every new wallpaper recolors the desktop. Dark or light
follows the image. `theme help` lists the commands and themes.

## Desktop

Hyprland with a Quickshell frame around the screen. The left side of the
frame is the bar, top to bottom:

| Item | Hover | Click | Scroll |
| --- | --- | --- | --- |
| Clock | date | | |
| Workspace pills (this monitor) | | switch | step through |
| Brightness (laptops) | percentage | | 5% steps |
| Volume | output and level | left: mute, right: pwvucontrol | 5% steps, up to 150% |
| Network | connection | left: nmtui, right: Wi-Fi on/off | |
| Battery (laptops), power profile icon (desktop) | level, time left, power profile | cycle power profile | |
| Gear (bottom) | current theme | left: next theme, right: previous | |
| Dot in the bottom-right corner | | notes popup | |

Keys beyond the usual window management (`global/home/.config/hypr/hyprland.lua`
and `users/lex/home/.config/hypr/hyprland.lua`):

| Keys | Action |
| --- | --- |
| volume, mute, mic mute, brightness keys | change the value and show the swayosd popup |
| `SUPER + N` | night light on/off; it also follows the schedule in `global/home/.config/hypr/hyprsunset.conf` (4500 K from 21:00 to 07:00) |
| `SUPER + Print` | region screenshot to the clipboard |
| `SUPER + SHIFT + Print` | region screenshot into satty for annotation (Enter copies) |

## Power

Every host has three power profiles (performance, balanced, power-saver),
switched by clicking the battery or profile icon in the bar. The laptop uses
TLP for them, other hosts power-profiles-daemon (`global/power.nix`).

On the laptop (`hosts/laptop/power.nix`), plugging in selects balanced and
unplugging selects power-saver; performance is a manual choice:

| Profile | CPU | Screen and effects |
| --- | --- | --- |
| performance | turbo, performance EPP | 240 Hz, blur, shadows, animations |
| balanced | turbo, balance_performance EPP | 240 Hz, blur, shadows, animations |
| power-saver | no turbo, power EPP, iGPU capped at 900 MHz | 60 Hz, no blur, shadows or animations |

On battery the ethernet controller is unbound and NVIDIA Dynamic Boost is
stopped. The refresh rate and effects come from a user service in
`modules/desktop/hyprland.nix`, so they apply to any host with a laptop panel.

The laptop's NVIDIA GPU stays powered off unless something asks for it
(`modules.hardware.graphics.nvidia.hybrid.offloadOnly`): desktop programs
only see the Intel GPU. Steam, Heroic, Lutris and Prism Launcher run on the
NVIDIA GPU; anything else can with `nvidia-offload <command>`. Check whether
it is powered off with
`cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` (`suspended`).

An external display attached to the NVIDIA GPU at login keeps it awake: the
`start-hyprland` wrapper then gives the compositor the NVIDIA EGL driver so it
can render to that display. Displays plugged in later need a Hyprland restart.

Closing the laptop lid only turns the panel off, so work keeps running.
`Fn + F1` suspends, then hibernates after 30 minutes. Swap is zswap in front
of a 40 GB partition (`modules.performance.swap = "zswap"`), large enough to
hibernate; the desktop keeps zram only.

The laptop's disks are not encrypted yet. LUKS for `ROOT`, `DATA` and the
swap partition is planned; the unallocated space at the end of the disk leaves
room to migrate.

Nix builds use at most `modules.performance.buildThreads` CPU threads (28 of
32 on the laptop, 12 of 16 on the desktop) at batch priority.

### Laptop charge limit (untested)

The firmware has no charge limit Linux can use without a platform driver.
`hosts/laptop/uniwill.nix` builds a copy of the mainline `uniwill-laptop`
driver restricted to this barebone's features; binding it sets the charge mode
to Trickle (stop at 80%). Another reseller's unit of the same chassis kept
charging to 100% in that mode, so test it once, plugged in, above 80%:

```sh
sudo modprobe uniwill_gm6ix force=1
cat /sys/class/power_supply/BAT0/charge_types      # [Trickle] Standard Long Life
cat /sys/class/power_supply/BAT0/{status,current_now}   # not "Charging" above 80%
```

If it keeps charging, `sudo modprobe -r uniwill_gm6ix` and leave it unloaded.
If it stops, add `uniwill_gm6ix` to `boot.kernelModules` with
`boot.extraModprobeConfig = "options uniwill_gm6ix force=1"`. Before a trip,
`echo Standard | sudo tee /sys/class/power_supply/BAT0/charge_types` charges
to 100% until the next boot.

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
nh os switch                                 # or: sudo nixos-rebuild switch --flake .#laptop
nix flake check                              # formatting, host evaluation, hyprland.lua syntax, package tests
nix fmt .                                    # alejandra
```
