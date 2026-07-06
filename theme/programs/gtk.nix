{theme, ...}: {
  homeFiles = {
    ".gtkrc-2.0".text = theme.outputs.gtk2Rc;
  };

  xdgConfigFiles = {
    "gtk-3.0/settings.ini".text = theme.outputs.gtk3Settings;
    "gtk-3.0/gtk.css".text = theme.outputs.gtk3Css;
    "gtk-3.0/gtk-dark.css".text = theme.outputs.gtk3DarkCss;
    "gtk-4.0/settings.ini".text = theme.outputs.gtk4Settings;
    "gtk-4.0/gtk.css".text = theme.outputs.gtk4Css;
    "gtk-4.0/gtk-dark.css".text = theme.outputs.gtk4DarkCss;
  };

  environmentEtc = {
    "gtk-2.0/gtkrc".text = theme.outputs.gtk2Rc;
    "xdg/gtk-3.0/settings.ini".text = theme.outputs.gtk3Settings;
    "xdg/gtk-3.0/gtk.css".text = theme.outputs.gtk3Css;
    "xdg/gtk-3.0/gtk-dark.css".text = theme.outputs.gtk3DarkCss;
    "xdg/gtk-4.0/settings.ini".text = theme.outputs.gtk4Settings;
    "xdg/gtk-4.0/gtk.css".text = theme.outputs.gtk4Css;
    "xdg/gtk-4.0/gtk-dark.css".text = theme.outputs.gtk4DarkCss;
  };
}
