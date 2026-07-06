{theme, ...}: {
  xdgConfigFiles = {
    "kitty/theme.conf".text = theme.outputs.kittyTheme;
  };
}
