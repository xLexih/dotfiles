# The dynamic theme: colors derived from the wallpaper at runtime.
#
# It's rendered like any named theme, once per variant, but every palette
# color is a sentinel (#e1e210 to #e1e21f; "e" never occurs in store paths).
# `theme` asks matugen for two Material You schemes of the wallpaper: one
# seeded by its dominant color, one by its most vivid. It picks the template
# for the scheme's dark/light mode and replaces each sentinel, in every format
# the targets write (#rrggbb, rrggbb, "r,g,b", "r;g;b"), with the scheme color
# below, tinted per `tint`. Everything else (roles, terminal, GTK, Qt, ...)
# derives from the palette, so every target supports it without changes.
{lib, ...}: let
  # Palette key -> "<scheme>.<matugen color>" for each mode. Surfaces and text
  # come from the dominant color so the desktop has the wallpaper's overall
  # tint; the accent comes from the vivid one, and accentAlt is the dominant
  # color's primary. A single-color wallpaper falls back to `sameSource`.
  # green/yellow/blue/cyan are the default theme's colors, harmonized toward
  # the wallpaper by matugen.
  roles = {
    dark = {
      bg = "dominant.surface_container_low";
      bgDark = "dominant.surface";
      bgDarker = "dominant.surface_container_lowest";
      surface = "dominant.surface_container_high";
      overlay = "dominant.outline_variant";
      fg = "dominant.on_surface";
      fgMuted = "dominant.on_surface_variant";
      accent = "vivid.primary";
      accentAlt = "dominant.primary";
      accentBright = "vivid.primary_fixed";
      shadow = "dominant.shadow";
      red = "vivid.error";
      green = "vivid.green";
      yellow = "vivid.yellow";
      blue = "vivid.blue";
      cyan = "vivid.cyan";
    };
    light = {
      bg = "dominant.surface";
      bgDark = "dominant.surface_container";
      bgDarker = "dominant.surface_container_highest";
      surface = "dominant.surface_container_lowest";
      overlay = "dominant.outline_variant";
      fg = "dominant.on_surface";
      fgMuted = "dominant.on_surface_variant";
      accent = "vivid.primary";
      accentAlt = "dominant.primary";
      accentBright = "vivid.on_primary_fixed_variant";
      shadow = "dominant.surface_dim";
      red = "vivid.error";
      green = "vivid.green";
      yellow = "vivid.yellow";
      blue = "vivid.blue";
      cyan = "vivid.cyan";
    };
  };

  # When both schemes share a seed, dominant.primary is the accent itself.
  sameSource.accentAlt = "vivid.tertiary";

  # Material's neutral palettes are nearly gray (OKLCH chroma about 0.01), so
  # the screen frame and every surface came out gray whatever the wallpaper.
  # `theme` keeps each neutral's lightness but gives it the dominant color's
  # hue at this OKLCH chroma, the amounts hexagon and hexagon-light use. A
  # wallpaper whose dominant color is less colorful than `reference` gets
  # proportionally less, so muted images stay muted.
  tint = {
    reference = 0.05;
    dark = {
      bgDarker = 0.024;
      bgDark = 0.032;
      bg = 0.04;
      surface = 0.056;
      overlay = 0.07;
      fg = 0.024;
      fgMuted = 0.05;
    };
    light = {
      surface = 0.006;
      bg = 0.012;
      bgDark = 0.02;
      bgDarker = 0.03;
      overlay = 0.03;
      shadow = 0.03;
      fg = 0.05;
      fgMuted = 0.055;
    };
  };

  keys = lib.attrNames roles.dark;
  sentinels = lib.listToAttrs (lib.imap0 (i: key: lib.nameValuePair key "e1e2${lib.toLower (lib.toHexString (16 + i))}") keys);
in {
  inherit roles sameSource tint sentinels;

  # Theme module for one variant.
  template = variant: {
    name = "dynamic";
    inherit variant;
    palette = lib.mapAttrs (_: sentinel: "#${sentinel}") sentinels;
  };
}
