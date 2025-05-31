# BIG THANKS TO https://github.com/Rexcrazy804/Zaphkiel
# Setup
Symlink setup is needed, because I don't want to clone this into /etc/nixos and have root own it, yock yock, we can just symlink and modify it normally ourselves~
```bash
sudo ln -s /home/lex/dotfiles/flake.nix /etc/nixos/flake.nix
```
Once the flake is int he correct location, the next step is to setup the flake for the correct machine
```
sudo nixos-rebuild switch --flake .#[desktop]
```
### Helpful commands used while working on the configuration.

`nix flake init --template github:aylur/ags`
