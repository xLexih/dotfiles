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
See [docs/config-layers.md](docs/config-layers.md) for the exact placement and merge rules.

## Software Layout

Software lives in one of three places depending on what it needs:

| Need | Location | Example |
| ---- | -------- | ------- |
| Plain package | `user/<name>/lib/packages.nix` | Kitty, VSCodium, development tools |
| Custom build or patch | `overlay/` | Codium with extensions, Krita plugins |
| System services or NixOS options | `module/software/` | Docker, Sunshine, libvirt |

**Overlays** override or wrap upstream packages — theme patches, bundled extensions, version pins, build fixes. Plain `overlay/*.nix` files are auto-discovered, while parameterized overlays stay explicit. The modified package is then installed from the user config like any other package.

**module/software/** is reserved for software that genuinely requires system-level integration: services, firewall rules, kernel modules, or virtualization. If it can run as a plain user package, it belongs in the user config or an overlay instead.

Themes are discovered from `theme/<name>/default.nix`. Enable one with `modules.theme = { enable = true; name = "<name>"; };`. Program-specific theme targets live in `theme/programs/`, so adding a new themed application should usually mean adding one small target file instead of expanding `theme/module.nix`.

## Rough Repository Structure

```
.
├── .config/               # Global dotfiles shared across all hosts/users
├── host/<device_name>     # Per-machine configuration
│   ├── .config/           # Host-specific dotfile overrides
│   ├── boot/              # Bootloader and initrd
│   ├── hardware/          # Machine-specific hardware (disks, peripherals)
│   └── storage/           # Filesystem mounts and swap
├── lib/                   # Nix helpers (mkSystem, dotfile layering logic)
├── module/                # Reusable NixOS modules
│   ├── base/              # Core system defaults
│   ├── hardware/          # CPU, GPU, audio, kernel, power
│   ├── network/           # Networking and firewall
│   ├── nix/               # Nix daemon and store settings
│   ├── performance/       # Schedulers, memory, tuning
│   ├── session/           # Display manager and window manager
│   └── software/          # System-level services (docker, VMs, etc.)
├── overlay/               # Custom package builds and patches
├── theme/                 # Theme definitions, program targets, generated outputs
├── user/<user_name>/      # User packages and personal dotfiles
│   ├── .config/           # User-specific dotfile overrides
│   └── lib/               # User helper files excluded from import-tree
└── flake.nix              # Entry point — hosts, inputs, checks
```

## Validation

```bash
nix flake check path:.
```

This runs all checks defined in the flake: evaluation of each host configuration, contract assertions (hostName, stateVersion, CPU vendor, theme), formatting with Alejandra, and import-tree hygiene (ensuring non-default Nix files are referenced or placed in a `lib/` helper directory). The top-level checks intentionally skip `host/homelab`, which is maintained as its own flake/subproject.
