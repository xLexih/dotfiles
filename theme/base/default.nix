# Theme base. Each theme/<name>.nix is a named theme: a module evaluated against
# options.nix, so it only sets the colors and settings it wants to change.
# The dynamic theme (dynamic.nix) derives its palette from the wallpaper.
#
# Targets (targets/*.nix) turn a theme into program configuration:
#   modules.theme.render.<target>   theme -> { "<path in $HOME>" = text; }
#   modules.theme.metadata.<key>    theme -> value, added to theme.json
#   modules.theme.reload.<target>   shell run after a switch so running
#                                   programs pick up the new files
# Every theme is rendered into /etc/themes/<name> (the dynamic one as a dark
# and a light template). The `theme` command (also behind the gear in the
# bar) copies one into $HOME, remembers it in ~/.local/state/theme/name and
# runs the reload hooks. The choice survives rebuilds: every rebuild applies it
# again (after hjem), which also resets edits to theme files like other
# managed dotfiles, and Hyprland runs the hooks at login (`theme reload`).
# Rendered files may use @HOME@ for the user's home directory.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.theme;
  dynamic = import ./dynamic.nix {inherit lib;};

  themeFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (builtins.readDir ../.);

  evalTheme = modules:
    (lib.evalModules {
      modules = [./options.nix] ++ modules;
      specialArgs = {inherit pkgs;};
    }).config;

  themes = lib.mapAttrs' (file: _: let
    name = lib.removeSuffix ".nix" file;
  in
    lib.nameValuePair name (evalTheme [../${file} {name = lib.mkDefault name;}]))
  themeFiles;

  dynamicTemplates = lib.genAttrs ["dark" "light"] (variant: evalTheme [(dynamic.template variant)]);

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

  themesDir = pkgs.linkFarm "themes" (
    lib.mapAttrs themeDir themes
    // {dynamic = pkgs.linkFarm "theme-dynamic" (lib.mapAttrs (variant: themeDir "dynamic-${variant}") dynamicTemplates);}
  );

  # matugen harmonizes the default theme's terminal colors toward the
  # wallpaper; the Material scheme has no green, yellow, blue or cyan.
  matugenConfig = let
    p = themes.${cfg.default}.palette;
  in
    pkgs.writeText "matugen.toml" ''
      [config.custom_colors]
      ${lib.concatMapStrings (key: ''
        ${key} = { color = "${p.${key}}", blend = true }
      '') ["green" "yellow" "blue" "cyan"]}
      [templates]
    '';

  themeCommand = pkgs.writeShellApplication {
    name = "theme";
    runtimeInputs = with pkgs; [awww coreutils findutils gawk gnused jq matugen];
    text = ''
      themes=/etc/themes
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/theme"
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}/theme"

      # Outside the session (the activation service) find the user's session
      # bus and newest Hyprland instance, so reload hooks reach them.
      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
      if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -d "$XDG_RUNTIME_DIR/hypr" ]; then
        HYPRLAND_INSTANCE_SIGNATURE=$(find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' |
          sort -n | tail -1 | cut -d' ' -f2)
        export HYPRLAND_INSTANCE_SIGNATURE
      fi

      usage() {
        echo "usage: theme [current | list | set <name> | next | prev | apply | reload | wallpaper <image>]" >&2
        exit 1
      }

      names() {
        for dir in "$themes"/*; do
          name=$(basename "$dir")
          # Without a wallpaper there is nothing to derive colors from.
          if [ "$name" != dynamic ] || [ -f "$(cat "$state/wallpaper" 2>/dev/null)" ]; then
            echo "$name"
          fi
        done
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

      # Closest GNOME accent preset to a color, by hue.
      gnome_accent() {
        awk -v hex="''${1#\#}" 'BEGIN {
          r = strtonum("0x" substr(hex, 1, 2)) / 255
          g = strtonum("0x" substr(hex, 3, 2)) / 255
          b = strtonum("0x" substr(hex, 5, 2)) / 255
          max = r; if (g > max) max = g; if (b > max) max = b
          min = r; if (g < min) min = g; if (b < min) min = b
          if (max - min < 0.1) { print "slate"; exit }
          if (max == r) h = 60 * ((g - b) / (max - min))
          else if (max == g) h = 60 * ((b - r) / (max - min) + 2)
          else h = 60 * ((r - g) / (max - min) + 4)
          if (h < 0) h += 360
          if (h < 15 || h >= 345) print "red"
          else if (h < 45) print "orange"
          else if (h < 70) print "yellow"
          else if (h < 160) print "green"
          else if (h < 195) print "teal"
          else if (h < 255) print "blue"
          else if (h < 290) print "purple"
          else print "pink"
        }'
      }

      # Renders the dynamic theme for the current wallpaper into the cache
      # and points THEME_DIR at it.
      render_dynamic() {
        wallpaper=$(cat "$state/wallpaper" 2>/dev/null || true)
        if [ ! -f "$wallpaper" ]; then
          echo "the dynamic theme needs a wallpaper: theme wallpaper <image>" >&2
          exit 1
        fi

        scheme=$(matugen image "$wallpaper" --dry-run --json hex --mode smart --prefer saturation \
          --config ${matugenConfig} 2>/dev/null)
        mode=$(jq -r .mode <<<"$scheme")
        palette=$(jq -c --argjson roles ${lib.escapeShellArg (builtins.toJSON dynamic.roles)} --arg mode "$mode" \
          '. as $scheme | $roles[$mode] | map_values($scheme.colors[.].default.color | ascii_downcase)' <<<"$scheme")

        THEME_DIR="$cache/dynamic"
        rm -rf "$THEME_DIR"
        mkdir -p "$THEME_DIR"
        cp -rL "$themes/dynamic/$mode/." "$THEME_DIR"
        chmod -R u+w "$THEME_DIR"

        jq -r --argjson palette "$palette" 'to_entries[] | "\(.value) \($palette[.key])"' \
          <<<${lib.escapeShellArg (builtins.toJSON dynamic.sentinels)} |
          while read -r sentinel color; do
            hex=''${color#\#}
            from=$((16#''${sentinel:4:2}))
            r=$((16#''${hex:0:2}))
            g=$((16#''${hex:2:2}))
            b=$((16#''${hex:4:2}))
            printf 's/%s/%s/g\n' "$sentinel" "$hex"
            printf 's/\\<225,226,%d\\>/%d,%d,%d/g\n' "$from" "$r" "$g" "$b"
            printf 's/225;226;%d/%d;%d;%d/g\n' "$from" "$r" "$g" "$b"
          done >"$cache/dynamic.sed"
        find "$THEME_DIR" -type f -exec sed -i -f "$cache/dynamic.sed" {} +

        if grep -rqE 'e1e21[0-9a-f]|225[,;]226[,;]' "$THEME_DIR"; then
          echo "dynamic theme: some colors weren't replaced" >&2
          exit 1
        fi

        accent=$(gnome_accent "$(jq -r .accent <<<"$palette")")
        tmp=$(mktemp)
        jq --arg accent "'$accent'" --arg wallpaper "$wallpaper" \
          '.gtk["accent-color"] = $accent | .wallpaper = $wallpaper' "$THEME_DIR/theme.json" >"$tmp"
        mv -f "$tmp" "$THEME_DIR/theme.json"
      }

      apply() {
        if [ "$1" = dynamic ]; then
          render_dynamic
        else
          THEME_DIR="$themes/$1"
          if [ -z "$1" ] || [ ! -d "$THEME_DIR" ]; then
            echo "unknown theme: $1 (available: $(names | tr '\n' ' '))" >&2
            exit 1
          fi
        fi

        # Replace each file in one step, so programs watching it (the bar)
        # never read a half-written one.
        (cd "$THEME_DIR/home" && find -L . -type f) | while read -r path; do
          target="$HOME/''${path#./}"
          mkdir -p "$(dirname "$target")"
          tmp=$(mktemp "$target.XXXXXX")
          sed "s|@HOME@|$HOME|g" "$THEME_DIR/home/$path" >"$tmp"
          chmod 644 "$tmp"
          mv -f "$tmp" "$target"
        done

        mkdir -p "$state"
        echo "$1" >"$state/name"
        reload
      }

      # Runs the reload hooks for THEME_DIR.
      reload() {
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

      wallpaper() {
        file=$(realpath -e "$1")
        mkdir -p "$state"
        echo "$file" >"$state/wallpaper"
        awww img --transition-type fade --transition-duration 1 "$file" || true
        if [ "$(current)" = dynamic ]; then
          apply dynamic
        fi
      }

      case "''${1:-current}" in
        current) current ;;
        list) names ;;
        set) apply "''${2:-}" ;;
        next) step 1 ;;
        prev) step -1 ;;
        apply) apply "$(current)" ;;
        reload)
          name=$(current)
          THEME_DIR="$themes/$name"
          [ "$name" = dynamic ] && THEME_DIR="$cache/dynamic"
          reload
          ;;
        wallpaper) [ -n "''${2:-}" ] || usage; wallpaper "$2" ;;
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
      description = "Per target, a function from a theme to the files it writes, relative to $HOME. @HOME@ becomes the user's home directory.";
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
    environment.etc.themes.source = themesDir;

    # Re-applies each user's theme after every rebuild, once hjem has updated
    # their dotfiles (so files moving between hjem and `theme` don't clash).
    systemd.services = lib.mapAttrs' (user: _:
      lib.nameValuePair "theme-${user}" {
        description = "Apply the theme of ${user}";
        wantedBy = ["hjem.target"];
        after = ["hjem-activate@${user}.service"];
        restartTriggers = [themesDir];
        serviceConfig = {
          Type = "oneshot";
          User = user;
          ExecStart = "${lib.getExe themeCommand} apply";
        };
      })
    config.hjem.users;

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
