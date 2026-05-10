{ lib, config, ... }:
let
  cfg = config.theme;
in
{
  options.theme = {
    enable = lib.mkEnableOption "Theme configuration" // {
      description = "Enable GTK/Qt theme configuration for dark mode support.";
    };
    name = lib.mkOption {
      type = lib.types.enum [ "dark" ];
      default = "dark";
      example = "dark";
      description = "Theme name to apply. Currently only 'dark' is available.";
    };
  };

  imports = [
    ./dark
  ];
}
