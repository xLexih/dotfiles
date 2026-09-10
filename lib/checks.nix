{
  lib,
  inputs,
  self,
  systems,
}: let
  forAllSystems = lib.genAttrs systems;
in
  forAllSystems (
    system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      hostConfigs = lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system) self.nixosConfigurations;
      dotfilesLib = import (self + "/lib/dotfiles.nix") {inherit lib self;};
      themeRegistry = import (self + "/theme") {
        inherit lib;
        pkgs = null;
      };
      overlayFiles = lib.sort builtins.lessThan (
        builtins.attrNames (
          lib.filterAttrs (
            name: type:
              type
              == "regular"
              && lib.hasSuffix ".nix" name
              && !(builtins.elem name ["default.nix" "codium.nix"])
          )
          (builtins.readDir (self + "/overlay"))
        )
      );
      overlayFilesText = lib.concatStringsSep "," overlayFiles;
      parameterizedOverlayLeaks = lib.filter (name: builtins.elem name ["codium.nix"]) overlayFiles;
      parameterizedOverlayLeaksText = lib.concatStringsSep "," parameterizedOverlayLeaks;
      discoveredThemeNames = builtins.attrNames themeRegistry.themes;
      discoveredThemeNamesText = lib.concatStringsSep "," discoveredThemeNames;
      supportThemeNames = lib.filter (name: builtins.elem name ["programs" "templates"]) discoveredThemeNames;
      supportThemeNamesText = lib.concatStringsSep "," supportThemeNames;
      dotfileSample = dotfilesLib.mkHjemDotfiles {
        commonSubstitutions = themeRegistry.themes.${themeRegistry.default}.outputs.dotfileSubstitutions;
        hostName = "desktop";
        userName = "lex";
      };
      laptopDotfileSample = dotfilesLib.mkHjemDotfiles {
        commonSubstitutions = themeRegistry.themes.${themeRegistry.default}.outputs.dotfileSubstitutions;
        hostName = "laptop";
        userName = "lex";
      };
      defaultThemeTargets = import (self + "/theme/programs") {
        inherit lib pkgs;
        sharePickerBinary = "/run/current-system/sw/bin/false";
        theme = themeRegistry.themes.${themeRegistry.default};
      };
      shadowedXdgDotfiles =
        builtins.filter (
          name: builtins.hasAttr name defaultThemeTargets.xdgConfigFiles
        )
        (builtins.attrNames dotfileSample.xdgConfigFiles);
      shadowedXdgDotfilesText = lib.concatStringsSep "," shadowedXdgDotfiles;
      dotfileLayerNames = lib.concatStringsSep "," (map (layer: layer.name) dotfileSample.layers);
      dotfileHasHomeBashrc =
        if builtins.hasAttr ".bashrc" dotfileSample.files
        then "yes"
        else "no";
      dotfileHasHyprland =
        if builtins.hasAttr "hypr/hyprland.lua" dotfileSample.xdgConfigFiles
        then "yes"
        else "no";
      dotfileHasLegacyHyprland =
        if builtins.hasAttr "hypr/hyprland.conf" dotfileSample.xdgConfigFiles
        then "yes"
        else "no";
      desktopHyprlandLua = pkgs.writeText "hyprland-desktop.lua" dotfileSample.xdgConfigFiles."hypr/hyprland.lua".text;
      laptopHyprlandLua = pkgs.writeText "hyprland-laptop.lua" laptopDotfileSample.xdgConfigFiles."hypr/hyprland.lua".text;
      evalChecks =
        lib.mapAttrs' (
          name: cfg: let
            drvPath = builtins.unsafeDiscardStringContext cfg.config.system.build.toplevel.drvPath;
          in
            lib.nameValuePair "eval-${name}" (
              pkgs.runCommand "eval-${name}" {} ''
                printf '%s\n' ${lib.escapeShellArg drvPath} > $out
              ''
            )
        )
        hostConfigs;
      contractChecks =
        lib.mapAttrs' (
          name: cfg:
            lib.nameValuePair "contract-${name}" (
              pkgs.runCommand "contract-${name}" {} ''
                {
                  printf 'hostName=%s\n' ${lib.escapeShellArg cfg.config.networking.hostName}
                  printf 'stateVersion=%s\n' ${lib.escapeShellArg cfg.config.system.stateVersion}
                  printf 'cpuVendor=%s\n' ${lib.escapeShellArg cfg.config.modules.hardware.cpu.vendor}
                  printf 'themeName=%s\n' ${lib.escapeShellArg cfg.config.modules.theme.active.name}
                } > $out
              ''
            )
        )
        hostConfigs;
    in
      evalChecks
      // contractChecks
      // {
        formatting =
          pkgs.runCommand "alejandra-check" {
            nativeBuildInputs = with pkgs; [alejandra findutils];
          } ''
            cd ${self}
            find . \
              -path ./.git -prune -o \
              -type f -name '*.nix' -print0 \
              | xargs -0 alejandra --check
            touch $out
          '';

        import-tree-hygiene =
          pkgs.runCommand "import-tree-hygiene" {
            nativeBuildInputs = with pkgs; [findutils gnugrep ripgrep];
          } ''
            cd ${self}
            bad=0
            files="$(mktemp)"
            find module host user \
              -path '*/.config' -prune -o \
              -path '*/lib' -prune -o \
              -type f -name '*.nix' -print | sort > "$files"

            while IFS= read -r file; do
              base="$(basename "$file")"
              case "$base" in
                default.nix) continue ;;
              esac

              if ! rg -F --quiet "$base" flake.nix lib module host user overlay theme .config README.md; then
                echo "Unreferenced Nix file inside import-tree path must be referenced or moved under a lib/ helper directory: $file" >&2
                bad=1
              fi
            done < "$files"

            test "$bad" -eq 0
            touch $out
          '';

        dotfile-layer-contract = pkgs.runCommand "dotfile-layer-contract" {} ''
          test ${lib.escapeShellArg dotfileLayerNames} = ${lib.escapeShellArg "global,host,user"}
          test ${lib.escapeShellArg dotfileHasHomeBashrc} = ${lib.escapeShellArg "yes"}
          test ${lib.escapeShellArg dotfileHasHyprland} = ${lib.escapeShellArg "yes"}
          test ${lib.escapeShellArg dotfileHasLegacyHyprland} = ${lib.escapeShellArg "no"}
          test -z ${lib.escapeShellArg shadowedXdgDotfilesText}

          {
            printf 'layers=%s\n' ${lib.escapeShellArg dotfileLayerNames}
            printf 'homeBashrc=%s\n' ${lib.escapeShellArg dotfileHasHomeBashrc}
            printf 'hyprland=%s\n' ${lib.escapeShellArg dotfileHasHyprland}
            printf 'legacyHyprland=%s\n' ${lib.escapeShellArg dotfileHasLegacyHyprland}
            printf 'shadowedXdgDotfiles=%s\n' ${lib.escapeShellArg shadowedXdgDotfilesText}
          } > $out
        '';

        hyprland-lua-syntax = pkgs.runCommand "hyprland-lua-syntax" {nativeBuildInputs = [pkgs.lua];} ''
          luac -p ${desktopHyprlandLua}
          luac -p ${laptopHyprlandLua}
          touch $out
        '';

        theme-registry-contract = pkgs.runCommand "theme-registry-contract" {} ''
          test -z ${lib.escapeShellArg supportThemeNamesText}
          {
            printf 'themes=%s\n' ${lib.escapeShellArg discoveredThemeNamesText}
            printf 'supportThemes=%s\n' ${lib.escapeShellArg supportThemeNamesText}
          } > $out
        '';

        overlay-registry-contract = pkgs.runCommand "overlay-registry-contract" {} ''
          test -n ${lib.escapeShellArg overlayFilesText}
          test -z ${lib.escapeShellArg parameterizedOverlayLeaksText}
          {
            printf 'overlays=%s\n' ${lib.escapeShellArg overlayFilesText}
            printf 'parameterizedLeaks=%s\n' ${lib.escapeShellArg parameterizedOverlayLeaksText}
          } > $out
        '';

        theme-apps-contract = pkgs.runCommand "theme-apps-contract" {} ''
          printf '%s' ${lib.escapeShellArg (builtins.toJSON (lib.mapAttrs (_: t: t.apps) themeRegistry.themes))} > $out
        '';

        no-hardcoded-dri-nodes = pkgs.runCommand "no-hardcoded-dri-nodes" {} ''
          cd ${self}
          if grep -rn -E '/dev/dri/card[0-9]' .config host user module theme overlay lib; then
            echo 'hardcoded /dev/dri/cardN node: use /dev/dri/by-path/ (card numbers shift across boots)' >&2
            exit 1
          fi
          if grep -rn -E 'AQ_DRM_DEVICES.*/dev/dri/by-path' .config host user module theme overlay; then
            echo 'AQ_DRM_DEVICES with /dev/dri/by-path: by-path entries contain ":" which Aquamarine parses as a device separator and crashes Hyprland at initServer. Either drop AQ_DRM_DEVICES or use /dev/dri/cardN nodes.' >&2
            exit 1
          fi
          touch $out
        '';
      }
  )
