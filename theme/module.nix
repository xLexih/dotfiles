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

  enabledThemes = lib.filter (name: cfg.${name}.enable) themeNames;
  activeThemeName =
    if enabledThemes != []
    then lib.head enabledThemes
    else themeRegistry.default;
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
  mkThemedHjemUser = userName: let
    layeredDotfiles = dotfilesLib.mkHjemDotfiles {
      commonSubstitutions = themeDotfileSubstitutions // {
        "{{bash-preexec}}" = "${pkgs.bash-preexec}";
        "{{nix-direnv}}" = "${pkgs.nix-direnv}";
      };
      hostName = config.networking.hostName;
      inherit userName;
    };
  in {
    files =
      layeredDotfiles.files
      // {
        ".gtkrc-2.0".text = activeTheme.outputs.gtk2Rc;
        ".mozilla/firefox/profiles.ini".text = activeTheme.outputs.firefoxProfilesIni;
        ".mozilla/firefox/default/user.js".text = activeTheme.outputs.firefoxUserJs;
        ".mozilla/firefox/default/chrome/userContent.css".text = activeTheme.outputs.firefoxUserContent;
        ".mozilla/firefox/default/chrome/userChrome.css".text = activeTheme.outputs.firefoxUserChrome;
      };

    xdg.config.files =
      layeredDotfiles.xdgConfigFiles
      // {
        "gtk-3.0/settings.ini".text = activeTheme.outputs.gtk3Settings;
        "gtk-3.0/gtk.css".text = activeTheme.outputs.gtk3Css;
        "gtk-3.0/gtk-dark.css".text = activeTheme.outputs.gtk3DarkCss;
        "gtk-4.0/settings.ini".text = activeTheme.outputs.gtk4Settings;
        "gtk-4.0/gtk.css".text = activeTheme.outputs.gtk4Css;
        "gtk-4.0/gtk-dark.css".text = activeTheme.outputs.gtk4DarkCss;
        "kitty/theme.conf".text = activeTheme.outputs.kittyTheme;
        "Kvantum/kvantum.kvconfig".text = activeTheme.outputs.kvantumConfig;
        "kdeglobals".text = activeTheme.outputs.kdeGlobals;
        "kdedefaults/kdeglobals".text = activeTheme.outputs.kdeGlobals;
        "qt5ct/qt5ct.conf".text = activeTheme.outputs.qt5ctConfig;
        "qt5ct/colors/${activeTheme.outputs.qtctColorSchemeFileName}".text = activeTheme.outputs.qtctColorScheme;
        "qt6ct/qt6ct.conf".text = activeTheme.outputs.qt6ctConfig;
        "qt6ct/colors/${activeTheme.outputs.qtctColorSchemeFileName}".text = activeTheme.outputs.qtctColorScheme;
        "theme/palette.json".text = activeTheme.outputs.paletteJson;
        "theme/palette.sh".text = activeTheme.outputs.paletteShell;
        "hypr/xdph.conf".text = "screencopy:custom_picker_binary = ${sharePickerBinary}";
      };

    xdg.data.files = {
      "color-schemes/${activeTheme.outputs.kdeColorSchemeFileName}".text = activeTheme.outputs.kdeColorScheme;
    };
  };
in {
  options.modules.theme =
    lib.genAttrs themeNames (name: {
      enable = lib.mkEnableOption "the ${name} theme";
    })
    // {
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

  config = lib.mkIf (enabledThemes != []) {
    assertions = [
      {
        assertion = lib.length enabledThemes <= 1;
        message = "Only one theme can be enabled at a time. Currently enabled: ${lib.concatStringsSep ", " enabledThemes}";
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

    environment.etc = {
      "gtk-2.0/gtkrc".text = activeTheme.outputs.gtk2Rc;
      "xdg/gtk-3.0/settings.ini".text = activeTheme.outputs.gtk3Settings;
      "xdg/gtk-3.0/gtk.css".text = activeTheme.outputs.gtk3Css;
      "xdg/gtk-3.0/gtk-dark.css".text = activeTheme.outputs.gtk3DarkCss;
      "xdg/gtk-4.0/settings.ini".text = activeTheme.outputs.gtk4Settings;
      "xdg/gtk-4.0/gtk.css".text = activeTheme.outputs.gtk4Css;
      "xdg/gtk-4.0/gtk-dark.css".text = activeTheme.outputs.gtk4DarkCss;
      "xdg/Kvantum/kvantum.kvconfig".text = activeTheme.outputs.kvantumConfig;
      "xdg/kdeglobals".text = activeTheme.outputs.kdeGlobals;
      "xdg/kdedefaults/kdeglobals".text = activeTheme.outputs.kdeGlobals;
      "xdg/qt5ct/qt5ct.conf".text = activeTheme.outputs.qt5ctConfig;
      "xdg/qt5ct/colors/${activeTheme.outputs.qtctColorSchemeFileName}".text = activeTheme.outputs.qtctColorScheme;
      "xdg/qt6ct/qt6ct.conf".text = activeTheme.outputs.qt6ctConfig;
      "xdg/qt6ct/colors/${activeTheme.outputs.qtctColorSchemeFileName}".text = activeTheme.outputs.qtctColorScheme;
      "xdg/color-schemes/${activeTheme.outputs.kdeColorSchemeFileName}".text = activeTheme.outputs.kdeColorScheme;
    };

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
