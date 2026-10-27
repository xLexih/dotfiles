# The dynamic theme: colors derived from the wallpaper at runtime.
#
# It's rendered like any named theme, once per variant, but every palette
# color is a sentinel (#e1e210 to #e1e21f; "e" never occurs in store paths).
# `theme` asks matugen for two Material You schemes of the wallpaper: one
# seeded by its dominant color, one by its most vivid. It picks the template
# for the scheme's dark/light mode and replaces each sentinel, in every format
# the targets write (#rrggbb, rrggbb, "r,g,b", "r;g;b"), with the scheme color
# below. Everything else (roles, terminal, GTK, Qt, ...) derives from the
# palette, so every target supports it without changes.
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

  keys = lib.attrNames roles.dark;
  sentinels = lib.listToAttrs (lib.imap0 (i: key: lib.nameValuePair key "e1e2${lib.toLower (lib.toHexString (16 + i))}") keys);
in {
  inherit roles sameSource sentinels;

  # Theme module for one variant.
  template = variant: {
    name = "dynamic";
    inherit variant;
    palette = lib.mapAttrs (_: sentinel: "#${sentinel}") sentinels;
  };
}
