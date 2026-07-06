{theme, ...}: {
  xdgConfigFiles = {
    "Kvantum/kvantum.kvconfig".text = theme.outputs.kvantumConfig;
    "kdeglobals".text = theme.outputs.kdeGlobals;
    "kdedefaults/kdeglobals".text = theme.outputs.kdeGlobals;
    "qt5ct/qt5ct.conf".text = theme.outputs.qt5ctConfig;
    "qt5ct/colors/${theme.outputs.qtctColorSchemeFileName}".text = theme.outputs.qtctColorScheme;
    "qt6ct/qt6ct.conf".text = theme.outputs.qt6ctConfig;
    "qt6ct/colors/${theme.outputs.qtctColorSchemeFileName}".text = theme.outputs.qtctColorScheme;
  };

  xdgDataFiles = {
    "color-schemes/${theme.outputs.kdeColorSchemeFileName}".text = theme.outputs.kdeColorScheme;
  };

  environmentEtc = {
    "xdg/Kvantum/kvantum.kvconfig".text = theme.outputs.kvantumConfig;
    "xdg/kdeglobals".text = theme.outputs.kdeGlobals;
    "xdg/kdedefaults/kdeglobals".text = theme.outputs.kdeGlobals;
    "xdg/qt5ct/qt5ct.conf".text = theme.outputs.qt5ctConfig;
    "xdg/qt5ct/colors/${theme.outputs.qtctColorSchemeFileName}".text = theme.outputs.qtctColorScheme;
    "xdg/qt6ct/qt6ct.conf".text = theme.outputs.qt6ctConfig;
    "xdg/qt6ct/colors/${theme.outputs.qtctColorSchemeFileName}".text = theme.outputs.qtctColorScheme;
    "xdg/color-schemes/${theme.outputs.kdeColorSchemeFileName}".text = theme.outputs.kdeColorScheme;
  };
}
