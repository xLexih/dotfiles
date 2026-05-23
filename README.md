<div align="center"> 
# Dotfiles

**Declarative NixOS flake with layered dotfile management and per-host configuration**

[![NixOS](https://img.shields.io/badge/NixOS-unstable-3b5487?logo=NixOS)](https://nixos.org)
[![Flakes](https://img.shields.io/badge/Nix_Flakes-enabled-4d6dad?logo=NixOS)](https://wiki.nixos.org/wiki/Flakes)

</div>

---

## Contents

- [Configuration Layers](#configuration-layers)
- [Software Layout](#software-layout)
- [Repository Structure](#repository-structure)
- [Validation](#validation)

---

## Configuration Layers

Dotfiles are split across three layers that get merged into a single result per file:

```
.config/            → Global (shared across all hosts and users)
host/<name>/.config → Host-specific (hardware, display, keybinds)
user/<name>/.config → User-specific (personal preferences)
```

Text-based configs (`.conf`, `.ini`, `.sh`) are **concatenated** across all layers that exist, producing a merged result. Structured formats (`.json`, `.qml`, `.svg`, `.toml`, `.yaml`) use **last-wins** — the most specific layer replaces the others entirely.

Merged text files receive a warning banner so manual edits aren't mistaken for persistent changes.

## Software Layout

Software lives in one of three places depending on what it needs:

| Need | Location | Example |
| ---- | -------- | ------- |
| Plain package | `user/lex/default.nix` | Firefox, Spotify |
| Custom build or patch | `overlay/` | Codium with extensions, Krita plugins |
| System services or NixOS options | `module/software/` | Docker, Sunshine, libvirt |

**Overlays** override or wrap upstream packages — theme patches, bundled extensions, version pins, build fixes. The modified package is then installed from the user config like any other package.

**module/software/** is reserved for software that genuinely requires system-level integration: services, firewall rules, kernel modules, or virtualization. If it can run as a plain user package, it belongs in the user config or an overlay instead.

Themes are discovered from `theme/<name>/default.nix`. Enabling exactly one `modules.theme.<name>` option generates the GTK, Qt, Firefox, Kitty, and palette files for each configured user.

## Repository Structure

```
.
├── flake.nix                    # Entry point
├── .config/                     # Global dotfiles (layer 1)
│   ├── hypr/
│   ├── kitty/
│   ├── quickshell/
├── host/                        # Per-machine configuration
│   ├── desktop/
│   │   ├── .config/hypr/        # Host dotfiles (layer 2)
│   │   ├── boot/
│   │   ├── hardware/
│   │   └── storage/
│   └── laptop/
│       ├── .config/hypr/
│       ├── boot/
│       ├── hardware/
│       └── storage/
├── user/lex/                    # User packages and dotfiles (layer 3)
│   ├── default.nix
│   └── .config/
├── module/                      # Reusable NixOS modules
│   ├── base/
│   ├── hardware/
│   ├── network/
│   ├── nix/
│   ├── performance/
│   ├── session/
│   └── software/               # System-level software modules
│       ├── docker/
│       ├── obs/
│       ├── sunshine/
│       ├── virtual-machine/
│       └── waydroid/
├── overlay/                     # Package overrides and custom builds
├── theme/                       # Theme registry, helpers, and generated toolkit files
└── lib/                         # Nix helpers (mkSystem, dotfile layering)
```

## Validation

```bash
nix eval path:.#nixosConfigurations.laptop.config.system.build.toplevel.drvPath --raw
nix eval path:.#nixosConfigurations.desktop.config.system.build.toplevel.drvPath --raw
```
