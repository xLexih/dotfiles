# Color and font helpers shared by the targets.
{lib}: rec {
  # "#c6a0ff" -> "c6a0ff"
  hex = lib.removePrefix "#";

  # "#c6a0ff" -> { r = 198; g = 160; b = 255; }
  rgb = color: let
    h = hex color;
    channel = start: lib.fromHexString (builtins.substring start 2 h);
  in {
    r = channel 0;
    g = channel 2;
    b = channel 4;
  };

  # "#c6a0ff" -> "198,160,255"
  rgbCsv = color: let
    c = rgb color;
  in "${toString c.r},${toString c.g},${toString c.b}";

  # Qt's #AARRGGBB, opaque unless an alpha byte is given.
  argb = color: "#ff${hex color}";
  argbAlpha = alpha: color: "#${alpha}${hex color}";

  # "Noto Sans 11" -> { family = "Noto Sans"; size = "11"; }
  parseFont = font: let
    parts = lib.splitString " " font;
  in {
    family = lib.concatStringsSep " " (lib.init parts);
    size = lib.last parts;
  };

  # Font string in QFont::toString() format.
  qtFont = font: let
    f = parseFont font;
  in "${f.family},${f.size},-1,5,50,0,0,0,0,0";
}
