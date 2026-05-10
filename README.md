# Dotfiles
wowowow my dotfiles go brrrr

## Project Structure

```
.
├── flake.nix              # Main flake definition
├── flake.lock             # Locked dependencies
├── configuration.nix      # (Legacy) NixOS configuration
├── .gitignore             # Git ignore rules
├── overlays/              # Custom package overlays
├── users/                 # User-specific configurations
├── module/                # Reusable NixOS modules
│   ├── default.nix        # Main module imports
│   ├── coding/            # Programming language support
│   ├── graphics/          # Graphics drivers and utilities
│   ├── nix/               # Nix-specific tooling
│   ├── optimize/          # System optimization modules
│   ├── program/           # Application configurations
│   ├── system/            # Core system services
│   └── theme/             # Desktop themes
├── device/                # Machine-specific configurations
│   ├── desktop/           # Desktop PC settings
│   │   └── .config/       # Desktop-specific dotfiles
│   └── laptop/            # Laptop-specific settings
│       └── .config/       # Laptop-specific dotfiles
└── .config/               # Global dotfiles (managed by Hjem)
```

## Setup

Symlink setup is needed, because I don't want to clone this into `/etc/nixos` and have root own it, yock yock, we can just symlink and modify it normally ourselves~

```bash
nix-channel --add https://nixos.org/channels/nixos-unstable nixos
nix-channel --update
sudo ln -s /home/lex/dotfiles/flake.nix /etc/nixos/flake.nix
```

Once the flake is in the correct location, the next step is to setup the flake for the correct machine:

```bash
sudo nixos-rebuild switch --flake .#[desktop|laptop]
```

## Thanks

Special thanks to [Rexcrazy804/Zaphkiel](https://github.com/Rexcrazy804/Zaphkiel) for inspiration and foundational concepts.
