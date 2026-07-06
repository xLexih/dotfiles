{
  config,
  inputs,
  lib,
  pkgs,
  users ? [],
  ...
}: let
  cfg = config.modules.theme;
  themeRegistry = import (inputs.self + "/theme") {inherit lib pkgs;};
  overlayThemeRegistry = import (inputs.self + "/theme") {
    inherit lib;
    pkgs = null;
  };
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  dotfilesLib = import (inputs.self + "/lib/dotfiles.nix") {
    inherit lib;
    self = inputs.self;
  };
  themeNames = builtins.attrNames themeRegistry.themes;
  qmlImportPaths = [
    "${pkgs.quickshell}/lib/qt-6/qml"
    "${pkgs.qt6.qt5compat}/lib/qt-6/qml"
    "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
    "${pkgs.qt6.qtbase}/lib/qt-6/qml"
  ];

  legacyEnabledThemes = lib.filter (name: cfg.${name}.enable) themeNames;
  activeThemeName =
    if legacyEnabledThemes != []
    then lib.head legacyEnabledThemes
    else cfg.name;
  themeEnabled = cfg.enable || legacyEnabledThemes != [];
  activeTheme = themeRegistry.themes.${activeThemeName};
  activeOverlayTheme = overlayThemeRegistry.themes.${activeThemeName};

  themeSessionVariables = activeTheme.outputs.sessionVariables;
  spicetifyThemeDef = lib.attrByPath ["spicetify" "theme"] null activeTheme;
  spicetifyTheme =
    if spicetifyThemeDef == null
    then null
    else if lib.isString spicetifyThemeDef
    then spicePkgs.themes.${spicetifyThemeDef}
    else spicetifyThemeDef;
  spicetifyColorScheme = lib.attrByPath ["spicetify" "colorScheme"] null activeTheme;
  spicetifyCustomColorScheme = lib.attrByPath ["spicetify" "customColorScheme"] {} activeTheme;
  themeDotfileSubstitutions =
    activeTheme.outputs.dotfileSubstitutions
    // {
      "{{qml_import_paths_csv}}" = lib.concatStringsSep "," qmlImportPaths;
      "{{qml_import_paths_text}}" = lib.concatStringsSep ", " qmlImportPaths;
    };
  sharePickerBinary = let
    qss = pkgs.writeText "share-picker.qss" activeTheme.outputs.sharePickerQss;
    picker = "${pkgs.xdg-desktop-portal-hyprland}/bin/hyprland-share-picker";
  in
    pkgs.writeShellScript "hyprland-share-picker-themed" ''
      export QT_STYLE_OVERRIDE=Fusion
      exec ${picker} -stylesheet ${qss}
    '';
  themeTargets = import (inputs.self + "/theme/programs") {
    inherit lib pkgs sharePickerBinary;
    theme = activeTheme;
  };
  mkThemedHjemUser = userName: let
    layeredDotfiles = dotfilesLib.mkHjemDotfiles {
      commonSubstitutions =
        themeDotfileSubstitutions
        // {
          "{{bash-preexec}}" = "${pkgs.bash-preexec}";
          "{{nix-direnv}}" = "${pkgs.nix-direnv}";
        };
      hostName = config.networking.hostName;
      inherit userName;
    };
  in {
    files =
      layeredDotfiles.files
      // themeTargets.homeFiles;

    xdg.config.files =
      layeredDotfiles.xdgConfigFiles
      // themeTargets.xdgConfigFiles;

    xdg.data.files = themeTargets.xdgDataFiles;
  };
in {
  options.modules.theme =
    lib.genAttrs themeNames (name: {
      enable = lib.mkEnableOption "the ${name} theme";
    })
    // {
      enable = lib.mkEnableOption "system theming";
      name = lib.mkOption {
        type = lib.types.enum themeNames;
        default = themeRegistry.default;
        description = "Theme name to use when modules.theme.enable is set.";
      };
      available = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        readOnly = true;
        default = themeNames;
        description = "Themes discovered from theme/<name>/default.nix.";
      };
      activeName = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = activeThemeName;
        description = "Resolved active theme name after legacy per-theme enable flags are considered.";
      };
      active = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        readOnly = true;
        default = activeTheme;
        description = "Resolved theme data for other modules.";
      };
      sharePickerBinary = lib.mkOption {
        type = lib.types.path;
        readOnly = true;
        default = sharePickerBinary;
        description = "Path to the themed share picker wrapper.";
      };
      firefox = {
        userJs = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = activeTheme.outputs.firefoxUserJs;
        };
        userChrome = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = activeTheme.outputs.firefoxUserChrome;
        };
        userContent = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = activeTheme.outputs.firefoxUserContent;
        };
      };
      spicetify = {
        theme = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
          readOnly = true;
          default = spicetifyTheme;
        };
        colorScheme = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          readOnly = true;
          default = spicetifyColorScheme;
        };
        customColorScheme = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = spicetifyCustomColorScheme;
        };
      };
    };

  config = lib.mkIf themeEnabled {
    assertions = [
      {
        assertion = lib.length legacyEnabledThemes <= 1;
        message = "Only one legacy per-theme enable flag can be set at a time. Currently enabled: ${lib.concatStringsSep ", " legacyEnabledThemes}";
      }
      {
        assertion = !(cfg.enable && legacyEnabledThemes != [] && cfg.name != activeThemeName);
        message = "Conflicting theme selection: modules.theme.name is ${cfg.name}, but the legacy modules.theme.${activeThemeName}.enable flag is also set.";
      }
    ];

    fonts = {
      fontDir.enable = true;
      packages = themeRegistry.fonts.packages;
      fontconfig.defaultFonts = themeRegistry.fonts.defaultFonts;
    };

    qt = {
      enable = true;
      platformTheme = lib.mkDefault (activeTheme.qt.platformTheme or "qt5ct");
      style = lib.mkDefault (activeTheme.qt.style or "kvantum");
    };

    programs.dconf.enable = true;
    programs.dconf.profiles.user.databases = [
      {
        lockAll = true;
        settings = activeTheme.outputs.dconfSettings;
      }
    ];

    environment.etc = themeTargets.environmentEtc;

    environment.variables = activeTheme.outputs.environmentVariables;

    environment.sessionVariables = themeSessionVariables;

    programs.spicetify =
      lib.mkIf (spicetifyTheme != null) {
        theme = spicetifyTheme;
      }
      // lib.optionalAttrs (spicetifyColorScheme != null) {
        colorScheme = spicetifyColorScheme;
      }
      // lib.optionalAttrs (spicetifyCustomColorScheme != {}) {
        customColorScheme = spicetifyCustomColorScheme;
      };

    nixpkgs.overlays = [
      ((import (inputs.self + "/overlay/codium.nix")) {theme = activeOverlayTheme;})
    ];

    hjem.users = lib.genAttrs users mkThemedHjemUser;

    environment.systemPackages = with pkgs;
      [
        glib
        gsettings-desktop-schemas
        gnome-themes-extra
        kdePackages.breeze
        kdePackages.breeze-icons
        kdePackages.kde-cli-tools
        nwg-look
      ]
      ++ builtins.filter (pkg: pkg != null) [
        activeTheme.gtk.package
        activeTheme.icon.package
        activeTheme.cursor.package
      ];
  };
}
