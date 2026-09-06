# Themes

Named themes live in `theme/<name>/`. Discovery requires only
`theme/<name>/default.nix`; `programs` and `template(s)` are skipped, as are
`_`-prefixed directories.

## Layers

| Layer | Path | Content |
| --- | --- | --- |
| Palette | `theme/<name>/default.nix` (`ui`) | Raw hex colors, no semantics |
| Roles | derived via `helpers.mkThemeRoles` | Semantic aliases (`panelBg`, `focus`, …). Omit `roles` to use defaults; the helper merges explicit entries over derived ones |
| Template | `theme/templates/<app>.nix` | Full slot map for one program, bound to `ui`/`roles`. Shared by all themes |
| App overrides | `theme/<name>/apps/<app>.nix` | Partial map. Merged over the template with `recursiveUpdate`; record value deviations only |
| Render | `helpers.mk<App>Theme` + `theme/programs/<app>.nix` | Slot map to file text and placement. Global, not per theme |

Resolution is total by construction: template covers every slot, overrides
only replace. Unknown override keys `throw` at eval; `theme-apps-contract`
forces every theme's app maps so inactive themes fail the check too.

## Variants

One level of inheritance. Import the base theme, replace `ui`, re-derive
`roles`, add `apps` overrides, rebuild `outputs` from the base renderer:

```nix
{helpers, lib, pkgs ? null}: let
  base = import ../hexagon {inherit helpers lib pkgs;};
  ui = {/* light palette */};
  roles = helpers.mkThemeRoles {inherit ui;};
  apps = {
    kitty = helpers.resolveAppSlots
      (import ../templates/kitty.nix {inherit ui roles;})
      (import ./apps/kitty.nix {inherit ui roles;});
  };
  theme = base // {
    name = "hexagon-light";
    inherit ui roles apps;
  };
in
  theme // {outputs = import ../hexagon/outputs.nix {inherit helpers lib theme;};}
```

`theme/hexagon-light` follows this shape. Non-color sections (`gtk`, `qt`,
`font`, `icon`, `cursor`) inherit from the base; override the flavor keys
(`preferDark`, kvantum variant, look-and-feel) per variant. Omit `spicetify`
and the module skips it.

## Switching

`theme-switch <name>` swaps the live kitty config from pre-rendered store
outputs and reloads kitty (`SIGUSR1`). It records the choice in
`~/.config/theme/active`. Scope: session-live. GTK/Qt/Firefox apply on
restart; `nixos-rebuild` restores `modules.theme.name`, so set the option for
persistence.

## Adding a theme

Copy `theme/hexagon-light/default.nix`. Supply `ui`; omit `roles` unless a
role needs a non-derived value; add `apps/<app>.nix` files only for
deviating slots. The discovery, enum option, and contracts pick it up with no
further wiring.

## Adding an app

1. `theme/templates/<app>.nix`: `{ui, roles}` to full slot map.
2. Renderer in `theme/lib.nix` (`mk<App>Theme`), wired through the theme's
   `outputs.nix`.
3. `theme/programs/<app>.nix`: file placement from `theme.outputs`.
4. Per-theme `apps/<app>.nix` files as needed (none required when defaults
   hold).
