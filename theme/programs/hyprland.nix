{sharePickerBinary, ...}: {
  xdgConfigFiles = {
    "hypr/xdph.conf".text = "screencopy:custom_picker_binary = ${sharePickerBinary}";
  };
}
