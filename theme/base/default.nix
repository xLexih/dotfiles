# Theme base. Each theme/<name>.nix is a named theme: a module evaluated against
# options.nix, so it only sets the colors and settings it wants to change.
# The dynamic theme (dynamic.nix) derives its palette from the wallpaper.
#
# Targets (targets/) turn a theme into program configuration:
#   modules.theme.render.<target>   theme -> { "<path in $HOME>" = text; }
#   modules.theme.metadata.<key>    theme -> value, added to theme.json
#   modules.theme.reload.<target>   shell run after a switch so running
#                                   programs pick up the new files
# Every theme is rendered into /etc/themes/<name> (the dynamic one as a dark
# and a light template). The `theme` command (theme.sh, also behind the gear
# in the bar) installs one into $HOME, removes files of the previous one and
# runs the reload hooks. The choice survives rebuilds: a service re-applies it
# after hjem, and Hyprland runs the hooks at login (`theme reload`). Rendered
# files may use @HOME@ for the user's home directory.
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
      inherit (theme) name label variant colors terminal fonts;
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

  reloadHooks = pkgs.writeShellScript "theme-reload" ''
    theme_get() {
      ${lib.getExe pkgs.jq} -r "$1" "$THEME_DIR/theme.json"
    }

    # Hooks don't depend on each other, so they run in parallel.
    ${lib.concatStrings (lib.mapAttrsToList (target: script: ''
        # ${target}
        (
          ${script}
        ) >/dev/null 2>&1 &
      '')
      cfg.reload)}
    wait
  '';

  mkThemeCommand = themes:
    pkgs.writeShellApplication {
      name = "theme";
      runtimeInputs = with pkgs; [awww coreutils findutils gawk gnugrep gnused jq matugen resvg];
      text = ''
        themes=${themes}
        default_theme=${lib.escapeShellArg cfg.default}
        matugen_config=${matugenConfig}
        dynamic_roles=${pkgs.writeText "dynamic-roles.json" (builtins.toJSON {inherit (dynamic) roles sameSource;})}
        sentinels=${pkgs.writeText "dynamic-sentinels.json" (builtins.toJSON dynamic.sentinels)}
        reload_hooks=${reloadHooks}
        hyprland_walls=${config.programs.hyprland.package}/share/hypr

        ${builtins.readFile ./theme.sh}
      '';
    };

  themeCommand = mkThemeCommand themesDir;

  # Switches through every theme and the dynamic one (dark, light, SVG and
  # Hyprland's default test wallpapers) in an empty home: no placeholder
  # survives, each switch installs the right theme.json, text stays readable
  # (contrast.jq), dynamic follows the wallpaper's dominant color, and
  # switching back leaves no stale files.
  check =
    pkgs.runCommand "theme-check" {
      nativeBuildInputs = [themeCommand pkgs.imagemagick pkgs.jq];
    } ''
      export HOME=$TMPDIR/home XDG_RUNTIME_DIR=$TMPDIR/run
      mkdir -p $HOME $XDG_RUNTIME_DIR

      verify() {
        name=$(jq -r .name $HOME/.config/theme/theme.json)
        [ "$name" = "$1" ] || { echo "theme.json says $name after switching to $1"; exit 1; }
        if grep -rliE 'e1e21[0-9a-f]|225[,;]226[,;](1[6-9]|2[0-9]|3[01])([^0-9]|$)|@HOME@' --exclude-dir=.cache $HOME; then
          echo "placeholders left after switching to $1"
          exit 1
        fi
        unreadable=$(jq -r -f ${./contrast.jq} $HOME/.config/theme/theme.json)
        [ -z "$unreadable" ] || { echo "unreadable colors in $1:"; echo "$unreadable"; exit 1; }
      }

      [ "$(theme list | tail -1)" = dynamic ] || { echo "theme list doesn't end with dynamic"; exit 1; }
      for name in $(theme list | grep -vx dynamic); do
        theme set $name
        verify $name
      done
      if theme set dynamic 2>/dev/null; then
        echo "dynamic applied without a wallpaper"
        exit 1
      fi

      magick -size 64x64 gradient:'#10301c'-'#2f8f5f' dark.png
      magick -size 64x64 gradient:'#fbf3e6'-'#e9c9a0' light.png
      theme wallpaper dark.png
      theme set dynamic
      verify dynamic
      [ "$(jq -r .variant $HOME/.config/theme/theme.json)" = dark ]
      theme wallpaper light.png
      verify dynamic
      [ "$(jq -r .variant $HOME/.config/theme/theme.json)" = light ]

      # A navy SVG with a small orange sun: the surfaces must stay blue and
      # the accent orange, instead of everything following the vivid sun.
      cat > navy.svg <<'EOF'
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90">
        <rect width="160" height="90" fill="#13304a"/>
        <circle cx="120" cy="30" r="12" fill="#f29e4c"/>
      </svg>
      EOF
      theme wallpaper navy.svg
      verify dynamic
      hue() {
        jq -r ".colors.$1" $HOME/.config/theme/theme.json |
          awk '{ r = strtonum("0x" substr($0, 2, 2)); b = strtonum("0x" substr($0, 6, 2)); print (b > r ? "blue" : "warm") }'
      }
      [ "$(hue bg)" = blue ] || { echo "dynamic bg doesn't follow the dominant navy"; exit 1; }
      [ "$(hue accent)" = warm ] || { echo "dynamic accent doesn't follow the orange sun"; exit 1; }

      # `default` goes back to Hyprland's own wallpapers, a different one each time.
      for _ in 1 2; do
        before=$(cat $HOME/.local/state/theme/wallpaper)
        theme wallpaper default
        verify dynamic
        after=$(cat $HOME/.local/state/theme/wallpaper)
        [ "$after" != "$before" ] || { echo "wallpaper default kept $before"; exit 1; }
        [ "$after" = "${config.programs.hyprland.package}/share/hypr/''${after##*/}" ] || { echo "wallpaper default chose $after"; exit 1; }
      done

      theme set ${cfg.default}
      installed=$(cd $HOME && find . -path ./.local/state -prune -o -path ./.cache -prune -o -type f -print | wc -l)
      [ "$installed" = "$(wc -l < $HOME/.local/state/theme/files)" ] || { echo "stale theme files left behind"; exit 1; }

      touch $out
    '';
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
    system.checks = [check];

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
      themePaths = [".config/theme/theme.json"] ++ lib.attrNames (renderFiles themes.${cfg.default});
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
