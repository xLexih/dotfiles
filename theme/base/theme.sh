# theme: switch the desktop theme. Nix prepends the configuration:
#   themes           directory with one rendered theme per name, plus dynamic/{dark,light}
#   default_theme    theme used until the user picks one
#   matugen_config   matugen config with the colors to harmonize
#   dynamic_roles    JSON: palette key -> "<scheme>.<matugen color>" per mode, and the
#                    overrides for single-color wallpapers (see dynamic.nix)
#   sentinels        JSON: palette key -> placeholder hex in the dynamic templates
#   reload_hooks     script run with THEME_DIR after a switch
#   hyprland_walls   directory with Hyprland's own wall*.png wallpapers
# shellcheck disable=SC2154

state="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/theme"

# Outside the session (the activation service) find the user's session bus
# and newest Hyprland instance, so reload hooks reach them.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -d "$XDG_RUNTIME_DIR/hypr" ]; then
  HYPRLAND_INSTANCE_SIGNATURE=$(find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' |
    sort -n | tail -1 | cut -d' ' -f2)
  export HYPRLAND_INSTANCE_SIGNATURE
fi

die() {
  echo "theme: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: theme [<command>]

Switch the desktop theme at runtime, no rebuild needed.

Commands:
  current             Print the active theme (the default command)
  list                List the themes, * marks the active one; piped, names only
  set <name>          Apply a theme
  next, prev          Apply the next or previous theme (the gear in the bar)
  apply               Reinstall the active theme's files, undoing manual edits
  reload              Re-run the reload hooks without reinstalling files
  wallpaper <image>   Set the wallpaper: PNG, JPEG, WebP, SVG, ...
  wallpaper default   Go back to one of Hyprland's own wallpapers, a different
                      one each time
  help                Show this help

Themes:
USAGE
  table | sed 's/^/  /'
  cat <<'USAGE'

dynamic takes its colors from the wallpaper: surfaces from its dominant
color, the accent from its most vivid one, dark or light from its
brightness. Pick an image with `theme wallpaper <image>`, then run
`theme set dynamic`; while it's active, every new wallpaper recolors the
desktop.

Named themes are theme/<name>.nix in the dotfiles; see docs/themes.md.
USAGE
}

# The image set with `theme wallpaper`, if it still exists.
wallpaper_file() {
  file=$(cat "$state/wallpaper" 2>/dev/null) && [ -f "$file" ] && echo "$file"
}

# Every theme: the named ones, then dynamic.
names() {
  for dir in "$themes"/*; do
    [ "${dir##*/}" = dynamic ] || echo "${dir##*/}"
  done
  echo dynamic
}

# The themes `next` and `prev` cycle through: dynamic only with a wallpaper.
available() {
  names | while read -r name; do
    if [ "$name" != dynamic ] || wallpaper_file >/dev/null; then
      echo "$name"
    fi
  done
}

current() {
  name=$(cat "$state/name" 2>/dev/null || true)
  if [ -z "$name" ] || [ ! -d "$themes/$name" ]; then
    name=$default_theme
  fi
  echo "$name"
}

theme_dir() {
  if [ "$1" = dynamic ]; then
    echo "$cache/dynamic"
  else
    echo "$themes/$1"
  fi
}

# One aligned line per theme: active marker, name, label, variant and, for
# dynamic, the wallpaper it follows.
table() {
  active=$(current)
  rows_name=() rows_label=() rows_variant=() rows_detail=()
  while read -r name; do
    rows_name+=("$name")
    if [ "$name" != dynamic ]; then
      rows_label+=("$(jq -r .label "$themes/$name/theme.json")")
      rows_variant+=("$(jq -r .variant "$themes/$name/theme.json")")
      rows_detail+=("")
    elif wallpaper=$(wallpaper_file); then
      rows_label+=(Dynamic)
      # The mode is only known once matugen has seen the image.
      if dynamic_fresh "$wallpaper"; then
        rows_variant+=("$(jq -r .variant "$cache/dynamic/theme.json")")
      else
        rows_variant+=(auto)
      fi
      rows_detail+=("from $wallpaper")
    else
      rows_label+=(Dynamic)
      rows_variant+=(-)
      rows_detail+=("needs a wallpaper: theme wallpaper <image>")
    fi
  done < <(names)

  name_width=0 label_width=0
  for i in "${!rows_name[@]}"; do
    if [ "${#rows_name[i]}" -gt "$name_width" ]; then name_width=${#rows_name[i]}; fi
    if [ "${#rows_label[i]}" -gt "$label_width" ]; then label_width=${#rows_label[i]}; fi
  done
  for i in "${!rows_name[@]}"; do
    marker=' '
    if [ "${rows_name[i]}" = "$active" ]; then marker='*'; fi
    line=$(printf '%s %-*s  %-*s  %-5s  %s' "$marker" "$name_width" "${rows_name[i]}" \
      "$label_width" "${rows_label[i]}" "${rows_variant[i]}" "${rows_detail[i]}")
    echo "${line%"${line##*[! ]}"}"
  done
}

# Closest GNOME accent preset to a color, by hue.
gnome_accent() {
  awk -v hex="${1#\#}" 'BEGIN {
    r = strtonum("0x" substr(hex, 1, 2)) / 255
    g = strtonum("0x" substr(hex, 3, 2)) / 255
    b = strtonum("0x" substr(hex, 5, 2)) / 255
    max = r; if (g > max) max = g; if (b > max) max = b
    min = r; if (g < min) min = g; if (b < min) min = b
    if (max - min < 0.1) { print "slate"; exit }
    if (max == r) h = 60 * ((g - b) / (max - min))
    else if (max == g) h = 60 * ((b - r) / (max - min) + 2)
    else h = 60 * ((r - g) / (max - min) + 4)
    if (h < 0) h += 360
    if (h < 15 || h >= 345) print "red"
    else if (h < 45) print "orange"
    else if (h < 70) print "yellow"
    else if (h < 160) print "green"
    else if (h < 195) print "teal"
    else if (h < 255) print "blue"
    else if (h < 290) print "purple"
    else print "pink"
  }'
}

dynamic_key() {
  echo "$1 $(stat -c '%Y %s' "$1") $themes $dynamic_roles"
}

# Whether the cached dynamic theme was rendered from this wallpaper.
dynamic_fresh() {
  [ "$(cat "$cache/dynamic.key" 2>/dev/null)" = "$(dynamic_key "$1")" ] &&
    [ -f "$cache/dynamic/theme.json" ]
}

# matugen only reads raster images, so an SVG is rendered for it; awww draws
# SVGs itself.
color_source() {
  case "${1,,}" in
    *.svg | *.svgz)
      resvg --width 512 "$1" "$cache/wallpaper.png" 2>/dev/null || die "can't render $1"
      echo "$cache/wallpaper.png"
      ;;
    *) echo "$1" ;;
  esac
}

# Material You scheme of an image as JSON; further arguments go to matugen.
scheme() {
  image=$1
  shift
  matugen image "$image" --dry-run --json hex --config "$matugen_config" "$@" 2>/dev/null ||
    die "can't read colors from $wallpaper"
}

# Renders the dynamic theme for the current wallpaper into the cache: the
# template for the scheme's mode, with every placeholder color replaced in
# each format targets write it (#rrggbb, rrggbb, r,g,b and r;g;b). The result
# is reused until the wallpaper file, the rendered themes or the role mapping
# change.
render_dynamic() {
  wallpaper=$(wallpaper_file) || die "dynamic needs a wallpaper first: theme wallpaper <image>"
  if dynamic_fresh "$wallpaper"; then
    return
  fi

  mkdir -p "$cache"
  image=$(color_source "$wallpaper")
  vivid=$(scheme "$image" --mode smart --prefer saturation)
  mode=$(jq -r .mode <<<"$vivid")
  dominant=$(scheme "$image" --mode "$mode" --source-color-index 0)
  palette=$(jq -nc --argjson dominant "$dominant" --argjson vivid "$vivid" --arg mode "$mode" \
    --slurpfile mapping "$dynamic_roles" '
      def seed($scheme): $scheme.colors.source_color.default.color;
      {$dominant, $vivid} as $schemes
      | $mapping[0].roles[$mode]
        + (if seed($dominant) == seed($vivid) then $mapping[0].sameSource else {} end)
      | map_values(split(".") as [$scheme, $color]
          | $schemes[$scheme].colors[$color].default.color | ascii_downcase)')
  dir="$cache/dynamic"

  rm -f "$cache/dynamic.key"
  rm -rf "$dir"
  mkdir -p "$dir"
  cp -rL "$themes/dynamic/$mode/." "$dir"
  chmod -R u+w "$dir"

  jq -r --argjson palette "$palette" 'to_entries[] | "\(.value) \($palette[.key])"' "$sentinels" |
    while read -r sentinel color; do
      hex=${color#\#}
      from=$((16#${sentinel:4:2}))
      r=$((16#${hex:0:2}))
      g=$((16#${hex:2:2}))
      b=$((16#${hex:4:2}))
      printf 's/%s/%s/g\n' "$sentinel" "$hex"
      printf 's/\\<225,226,%d\\>/%d,%d,%d/g\n' "$from" "$r" "$g" "$b"
      printf 's/225;226;%d\\([^0-9]\\|$\\)/%d;%d;%d\\1/g\n' "$from" "$r" "$g" "$b"
    done >"$cache/dynamic.sed"
  find "$dir" -type f -exec sed -i -f "$cache/dynamic.sed" {} +

  # Only the sentinels themselves: a real color may well start with 225,226.
  if grep -rqE 'e1e21[0-9a-f]|225[,;]226[,;](1[6-9]|2[0-9]|3[01])([^0-9]|$)' "$dir"; then
    echo "dynamic theme: some colors weren't replaced" >&2
    exit 1
  fi

  accent=$(gnome_accent "$(jq -r .accent <<<"$palette")")
  tmp=$(mktemp)
  jq --arg accent "'$accent'" --arg wallpaper "$wallpaper" \
    '.gtk["accent-color"] = $accent | .wallpaper = $wallpaper' "$dir/theme.json" >"$tmp"
  mv -f "$tmp" "$dir/theme.json"
  dynamic_key "$wallpaper" >"$cache/dynamic.key"
}

# Copies a file into $HOME in one step, so programs watching it (the bar,
# Firefox) never read a half-written one.
install_file() {
  target="$HOME/$2"
  mkdir -p "$(dirname "$target")"
  tmp=$(mktemp "$target.XXXXXX")
  sed "s|@HOME@|$HOME|g" "$1" >"$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$target"
  echo "$2"
}

apply() {
  if [ "$1" = dynamic ]; then
    render_dynamic
  fi
  dir=$(theme_dir "$1")
  if [ ! -f "$dir/theme.json" ]; then
    die "unknown theme: $1 (themes: $(names | paste -sd ' '))"
  fi

  mkdir -p "$state"
  {
    install_file "$dir/theme.json" .config/theme/theme.json
    (cd "$dir/home" && find -L . -type f) | while read -r path; do
      install_file "$dir/home/$path" "${path#./}"
    done
  } | sort >"$state/files.new"

  # Remove files the previous theme installed and this one doesn't.
  if [ -f "$state/files" ]; then
    comm -23 "$state/files" "$state/files.new" | while read -r path; do
      rm -f "$HOME/$path"
    done
  fi
  mv -f "$state/files.new" "$state/files"

  echo "$1" >"$state/name"
  THEME_DIR=$dir "$reload_hooks"
}

step() {
  mapfile -t list < <(available)
  now=$(current)
  index=0
  for i in "${!list[@]}"; do
    [ "${list[i]}" = "$now" ] && index=$i
  done
  apply "${list[(index + $1 + ${#list[@]}) % ${#list[@]}]}"
}

# One of Hyprland's wallpapers, other than the current one.
default_wallpaper() {
  now=$(cat "$state/wallpaper" 2>/dev/null || true)
  mapfile -t walls < <(find "$hyprland_walls" -maxdepth 1 -name 'wall*.png' | grep -vxF "$now" | sort)
  [ "${#walls[@]}" -gt 0 ] || die "no Hyprland wallpapers in $hyprland_walls"
  echo "${walls[RANDOM % ${#walls[@]}]}"
}

wallpaper() {
  file=$(realpath -e "$1" 2>/dev/null) || die "no such file: $1"
  mkdir -p "$state"
  echo "$file" >"$state/wallpaper"
  awww img --transition-type fade --transition-duration 1 "$file" || true
  # Rendered now, while the wallpaper fades in, so switching to dynamic later
  # doesn't wait for matugen.
  if [ "$(current)" = dynamic ]; then
    apply dynamic
  else
    render_dynamic
  fi
}

case "${1:-current}" in
  current) current ;;
  list)
    if [ -t 1 ]; then
      table
    else
      names
    fi
    ;;
  set)
    [ -n "${2:-}" ] || die "set needs a theme name: $(names | paste -sd ' ')"
    apply "$2"
    ;;
  next) step 1 ;;
  prev) step -1 ;;
  apply) apply "$(current)" ;;
  reload) THEME_DIR=$(theme_dir "$(current)") "$reload_hooks" ;;
  wallpaper)
    [ -n "${2:-}" ] || die "wallpaper needs an image: theme wallpaper <image> | default"
    image=$2
    if [ "$image" = default ]; then
      image=$(default_wallpaper)
    fi
    wallpaper "$image"
    ;;
  help | -h | --help) usage ;;
  *) die "unknown command: $1 (see theme help)" ;;
esac
