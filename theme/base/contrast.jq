# Text colors of a theme.json that read below 3:1 (WCAG contrast) against
# their background, one line each. Used by theme-check for every named theme
# and for the dynamic one generated from the test wallpapers.
def channel: if . <= 0.04045 then . / 12.92 else pow((. + 0.055) / 1.055; 2.4) end;
def byte: explode | map(if . >= 97 then . - 87 elif . >= 65 then . - 55 else . - 48 end) | .[0] * 16 + .[1];
def luminance: ltrimstr("#") as $hex
  | [$hex[0:2], $hex[2:4], $hex[4:6]] | map(byte / 255 | channel)
  | .[0] * 0.2126 + .[1] * 0.7152 + .[2] * 0.0722;
def contrast($a; $b): [($a | luminance), ($b | luminance)] | (max + 0.05) / (min + 0.05);

.variant as $variant
| .colors as $c
| .terminal as $t
| [
    ["fg", $c.fg, $c.bg],
    ["fgMuted", $c.fgMuted, $c.bg],
    ["accent", $c.accent, $c.surface],
    ["accentAlt", $c.accentAlt, $c.surface],
    ["accentBright", $c.accentBright, $c.surface],
    ["selectionFg", $c.selectionFg, $c.selectionBg],
    ["accentFg", $c.accentFg, $c.accent],
    # Shell prompts and programs print every ANSI color as text, except black
    # on a dark background, which is mostly used as a background itself.
    (("normal", "bright") as $group
      | $t[$group] | to_entries[]
      | select($variant == "light" or $group == "bright" or .key != "black")
      | ["terminal.\($group).\(.key)", .value, $t.background])
  ][]
| contrast(.[1]; .[2]) as $ratio
| select($ratio < 3)
| "\(.[0]) \(.[1]) on \(.[2]): \($ratio * 100 | round / 100):1"
