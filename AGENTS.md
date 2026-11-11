# Dotfiles instructions

NixOS flake repo: `hosts/` + `users/` + `modules/` + `global/`, with `pkgs/`
as flake outputs. Home files layer `global/home` < `hosts/<host>/home` <
`users/<user>/home` (same relative path lands in `$HOME`); managed copies are
writable but reset on rebuild.

- Never use imperative package managers. NixOS only; wrap repo tooling with
  `nix develop --command <cmd>` when direnv isn't loaded.
- `users/lex/omp.nix` owns the omp wrapper, its managed `--config` overlays,
  and the single-source agent conventions (`users/lex/omp-agents.md`, deployed
  to both `~/.config/omp/agent/AGENTS.md` and `~/.config/codex/AGENTS.md`).
- `~/.config/omp/agent/config.yml` is user-owned (model roles) and not deployed
  from the repo. Managed omp settings live in `users/lex/omp-behavior.yml` and
  `omp-look.yml` and win over it; don't add a repo copy of config.yml.
- omp honours `PI_CODING_AGENT_DIR` (set for pi in `global/xdg.nix`); the omp
  wrapper unsets it and sets `PI_CONFIG_DIR=.config/omp`, so omp's agent data
  lives in `~/.config/omp/agent`.
- Checks: `nix flake check`. Apply: `sudo nixos-rebuild switch --flake .#<host>`
  (`laptop` | `desktop`).
- Conventional Commits, one logical change per commit. Never commit unless asked.
