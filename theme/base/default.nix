# Theme base. Each theme/<name>.nix is a named theme: a module evaluated against
# options.nix, so it only sets the colors and settings it wants to change.
#
# Targets (targets/*.nix) turn a theme into program configuration:
#   modules.theme.render.<target>   theme -> { "<path in $HOME>" = text; }
#   modules.theme.metadata.<key>    theme -> value, added to theme.json
#   modules.theme.reload.<target>   shell run after a switch so running
#                                   programs pick up the new files
# Every theme is rendered into /etc/themes/<name>. The `theme` command (also
# behind the gear in the bar) copies one into $HOME, remembers it in
# ~/.local/state/theme/name and runs the reload hooks. The choice survives
# rebuilds: every rebuild and login applies it again, which also resets edits
# to theme files like other managed dotfiles.
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

  describe = theme:
    {
      inherit (theme) name variant palette roles terminal fonts;
      cursor = {inherit (theme.cursor) name size;};
    }
    // lib.mapAttrs (_: value: value theme) cfg.metadata;

  renderFiles = theme: lib.foldlAttrs (files: _: render: files // render theme) {} cfg.render;

  themeDir = name: theme:
    pkgs.linkFarm "theme-${name}" (
      {"theme.json" = pkgs.writeText "theme-${name}.json" (builtins.toJSON (describe theme));}
      // lib.mapAttrs' (path: text:
        lib.nameValuePair "home/${path}" (pkgs.writeText "theme-${name}-${lib.strings.sanitizeDerivationName (baseNameOf path)}" text))
      (renderFiles theme)
    );

  themeCommand = pkgs.writeShellApplication {
    name = "theme";
    runtimeInputs = with pkgs; [coreutils findutils jq];
    text = ''
      themes=/etc/themes
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/theme"

      usage() {
        echo "usage: theme [current | list | set <name> | next | prev | apply]" >&2
        exit 1
      }

      names() {
        for dir in "$themes"/*; do basename "$dir"; done
      }

      current() {
        name=$(cat "$state/name" 2>/dev/null || true)
        if [ -z "$name" ] || [ ! -d "$themes/$name" ]; then
          name=${lib.escapeShellArg cfg.default}
        fi
        echo "$name"
      }

      theme_get() {
        jq -r "$1" "$THEME_DIR/theme.json"
      }

      apply() {
        THEME_DIR="$themes/$1"
        if [ ! -d "$THEME_DIR" ]; then
          echo "unknown theme: $1 (available: $(names | tr '\n' ' '))" >&2
          exit 1
        fi

        # Replace each file in one step, so programs watching it (the bar)
        # never read a half-written one.
        (cd "$THEME_DIR/home" && find -L . -type f) | while read -r path; do
          target="$HOME/''${path#./}"
          mkdir -p "$(dirname "$target")"
          tmp=$(mktemp "$target.XXXXXX")
          cat "$THEME_DIR/home/$path" > "$tmp"
          chmod 644 "$tmp"
          mv -f "$tmp" "$target"
        done

        mkdir -p "$state"
        echo "$1" > "$state/name"

        ${lib.concatStrings (lib.mapAttrsToList (target: script: ''
          # ${target}
          (
            set +e
            ${script}
          ) >/dev/null 2>&1 || true
        '')
        cfg.reload)}
      }

      step() {
        mapfile -t list < <(names)
        now=$(current)
        index=0
        for i in "''${!list[@]}"; do
          [ "''${list[i]}" = "$now" ] && index=$i
        done
        apply "''${list[(index + $1 + ''${#list[@]}) % ''${#list[@]}]}"
      }

      case "''${1:-current}" in
        current) current ;;
        list) names ;;
        set) [ -n "''${2:-}" ] || usage; apply "$2" ;;
        next) step 1 ;;
        prev) step -1 ;;
        apply) apply "$(current)" ;;
        *) usage ;;
      esac
    '';
  };
in {
  imports = [(inputs.import-tree ./targets)];

  options.modules.theme = {
    default = lib.mkOption {
      type = lib.types.enum (lib.attrNames themes);
      default = "hexagon";
      description = "Theme used until a user picks one with `theme set` or the bar's gear.";
    };
    themes = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      default = themes;
      description = "Every named theme with all options resolved.";
    };
    describe = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      default = describe;
      description = "Function returning a theme's JSON description (theme.json, ~/.config/theme/palette.json).";
    };
    render = lib.mkOption {
      type = with lib.types; attrsOf (functionTo (attrsOf str));
      default = {};
      description = "Per target, a function from a theme to the files it writes, relative to $HOME.";
    };
    metadata = lib.mkOption {
      type = with lib.types; attrsOf (functionTo anything);
      default = {};
      description = "Extra values in theme.json, for reload hooks (`theme_get .<key>`).";
    };
    reload = lib.mkOption {
      type = with lib.types; attrsOf lines;
      default = {};
      description = "Per target, shell run after a switch. THEME_DIR and `theme_get <jq filter>` describe the new theme; failures are ignored.";
    };
  };

  config = {
    environment.systemPackages = [themeCommand];
    environment.etc.themes.source = pkgs.linkFarm "themes" (lib.mapAttrs themeDir themes);

    # Runs as each user on login and after every rebuild.
    system.userActivationScripts.theme = "${lib.getExe themeCommand} apply";

    assertions = let
      themePaths = lib.attrNames (renderFiles themes.${cfg.default});
    in
      lib.mapAttrsToList (user: hjem: let
        clashes = lib.intersectLists themePaths (lib.attrNames hjem.files);
      in {
        assertion = clashes == [];
        message = "Theme files can't also be dotfiles of ${user}: ${lib.concatStringsSep ", " clashes}";
      })
      config.hjem.users;
  };
}
