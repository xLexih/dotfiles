{theme, ...}: {
  xdgConfigFiles = {
    "theme/palette.json".text = theme.outputs.paletteJson;
    "theme/palette.sh".text = theme.outputs.paletteShell;
  };
}
