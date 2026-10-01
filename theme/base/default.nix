# Theme base. Each theme/<name>.nix is a named theme: a module evaluated against
# options.nix, so it only sets the colors and settings it wants to change.
# The selected theme is handed to the targets, which apply it to programs, and
# exposed to layered dotfiles as {{theme.*}} placeholders.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.theme;

  themeFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (builtins.readDir ../.);

  evalTheme = file:
    (lib.evalModules {
      modules = [
        ./options.nix
        ../${file}
        {name = lib.mkDefault (lib.removeSuffix ".nix" file);}
      ];
      specialArgs = {inherit pkgs;};
    }).config;

  themes = lib.mapAttrs' (file: _: lib.nameValuePair (lib.removeSuffix ".nix" file) (evalTheme file)) themeFiles;

  theme = cfg.active;
  colors = theme.palette // theme.roles;

  # theme-switch copies these pre-rendered files over the live ones.
  switchManifest = pkgs.writeText "theme-switch.json" (builtins.toJSON (lib.mapAttrs (name: t:
    lib.mapAttrs (path: render: pkgs.writeText "${name}-${baseNameOf path}" (render t)) cfg.live)
  themes));

  themeSwitch = pkgs.writeShellApplication {
    name = "theme-switch";
    runtimeInputs = [pkgs.jq pkgs.procps];
    text = ''
      name="''${1:?usage: theme-switch <theme>}"
      if ! jq -e --arg t "$name" 'has($t)' ${switchManifest} >/dev/null; then
        echo "unknown theme: $name (available: $(jq -r 'keys | join(" ")' ${switchManifest}))" >&2
        exit 1
      fi
      jq -r --arg t "$name" '.[$t] | to_entries[] | "\(.key)\t\(.value)"' ${switchManifest} |
        while IFS=$'\t' read -r path file; do
          install -Dm644 "$file" "$HOME/$path"
        done
      pkill -USR1 -x kitty || true
      echo "switched to $name until the next rebuild (set modules.theme.name to keep it)"
    '';
  };
in {
  imports = [(inputs.import-tree ./targets)];

  options.modules.theme = {
    name = lib.mkOption {
      type = lib.types.enum (lib.attrNames themes);
      default = "hexagon";
      description = "Named theme from theme/<name>.nix.";
    };
    active = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      default = themes.${cfg.name};
      description = "The selected theme with every option resolved.";
    };
    live = lib.mkOption {
      type = with lib.types; attrsOf (functionTo str);
      default = {};
      internal = true;
      description = "Renderers for files, relative to $HOME, that theme-switch swaps without a rebuild.";
    };
  };

  config = {
    environment.systemPackages = [themeSwitch];

    dotfiles.vars =
      {
        "theme.name" = theme.name;
        "theme.variant" = theme.variant;
        "theme.gtk" = theme.gtk.name;
        "theme.icons" = theme.icons.name;
        "theme.cursor" = theme.cursor.name;
        "theme.cursor.size" = toString theme.cursor.size;
        "theme.font.sans" = theme.fonts.sans;
        "theme.font.document" = theme.fonts.document;
        "theme.font.mono" = theme.fonts.mono;
      }
      // lib.concatMapAttrs (name: value: {
        "theme.${name}" = value;
        "theme.${name}.hex" = lib.removePrefix "#" value;
      })
      colors;
  };
}
