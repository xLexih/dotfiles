# The dynamic theme: colors derived from the wallpaper at runtime.
#
# It's rendered like any named theme, once per variant, but every palette
# color is a sentinel (#e1e210 to #e1e21f; "e" never occurs in store paths).
# `theme` asks matugen for a Material You scheme of the wallpaper, picks the
# template for the scheme's dark/light mode and replaces each sentinel, in
# every format the targets write (#rrggbb, rrggbb, "r,g,b", "r;g;b"), with
# the matching scheme color. Everything else (roles, terminal, GTK, Qt, ...)
# derives from the palette, so every target supports it without changes.
{lib, ...}: let
  # Palette key -> matugen color for each mode. green/yellow/blue/cyan are
  # the default theme's colors, harmonized toward the wallpaper by matugen.
  roles = {
    dark = {
      bg = "surface_container_low";
      bgDark = "surface";
      bgDarker = "surface_container_lowest";
      surface = "surface_container_high";
      overlay = "outline_variant";
      fg = "on_surface";
      fgMuted = "on_surface_variant";
      accent = "primary";
      accentAlt = "tertiary";
      accentBright = "primary_fixed";
      shadow = "shadow";
      red = "error";
      green = "green";
      yellow = "yellow";
      blue = "blue";
      cyan = "cyan";
    };
    light = {
      bg = "surface";
      bgDark = "surface_container";
      bgDarker = "surface_container_highest";
      surface = "surface_container_lowest";
      overlay = "outline_variant";
      fg = "on_surface";
      fgMuted = "on_surface_variant";
      accent = "primary";
      accentAlt = "tertiary";
      accentBright = "on_primary_fixed_variant";
      shadow = "surface_dim";
      red = "error";
      green = "green";
      yellow = "yellow";
      blue = "blue";
      cyan = "cyan";
    };
  };

  keys = lib.attrNames roles.dark;
  sentinels = lib.listToAttrs (lib.imap0 (i: key: lib.nameValuePair key "e1e2${lib.toLower (lib.toHexString (16 + i))}") keys);
in {
  inherit roles sentinels;

  # Theme module for one variant.
  template = variant: {
    name = "dynamic";
    inherit variant;
    palette = lib.mapAttrs (_: sentinel: "#${sentinel}") sentinels;
  };
}
