# Layout

Everything under `global/`, `modules/`, `hosts/<host>/` and `users/<user>/`
is imported automatically, so a new `.nix` file there is picked up without
being listed anywhere. `home/` directories are skipped: they hold dotfiles,
see [dotfiles.md](dotfiles.md).

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

## Templates

`templates/project` is a blank repo: dev shell, justfile, AGENTS.md and
age-encrypted private files. `nix flake init` without `-t` uses it, because
`global/nix.nix` points the registry's `templates` at this flake; it sees
template changes after a switch. NixOS's own templates are under
`nix flake init -t nixos-templates#<name>`.

nixpkgs comes from the nixos.org channel tarballs
(`https://channels.nixos.org/<branch>/nixexprs.tar.zst`), in this flake and in
the template: they are smaller than GitHub's archives and not rate limited.
