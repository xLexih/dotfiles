# theme: switch the desktop theme. Nix prepends the configuration:
#   themes           directory with one rendered theme per name, plus dynamic/{dark,light}
#   default_theme    theme used until the user picks one
#   matugen_config   matugen config with the colors to harmonize
#   dynamic_roles    JSON: palette key -> matugen color, per mode
#   sentinels        JSON: palette key -> placeholder hex in the dynamic templates
#   reload_hooks     script run with THEME_DIR after a switch
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

usage() {
  echo "usage: theme [current | list | set <name> | next | prev | apply | reload | wallpaper <image>]" >&2
  exit 1
}

names() {
  for dir in "$themes"/*; do
    name=$(basename "$dir")
    # Without a wallpaper there is nothing to derive colors from.
    if [ "$name" != dynamic ] || [ -f "$(cat "$state/wallpaper" 2>/dev/null)" ]; then
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

# Renders the dynamic theme for the current wallpaper into the cache: the
# template for the scheme's mode, with every placeholder color replaced in
# each format targets write it (#rrggbb, rrggbb, r,g,b and r;g;b).
render_dynamic() {
  wallpaper=$(cat "$state/wallpaper" 2>/dev/null || true)
  if [ ! -f "$wallpaper" ]; then
    echo "the dynamic theme needs a wallpaper: theme wallpaper <image>" >&2
    exit 1
  fi

  scheme=$(matugen image "$wallpaper" --dry-run --json hex --mode smart --prefer saturation \
    --config "$matugen_config" 2>/dev/null)
  mode=$(jq -r .mode <<<"$scheme")
  palette=$(jq -c --slurpfile roles "$dynamic_roles" --arg mode "$mode" \
    '. as $scheme | $roles[0][$mode] | map_values($scheme.colors[.].default.color | ascii_downcase)' <<<"$scheme")

  dir="$cache/dynamic"
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
      printf 's/225;226;%d/%d;%d;%d/g\n' "$from" "$r" "$g" "$b"
    done >"$cache/dynamic.sed"
  find "$dir" -type f -exec sed -i -f "$cache/dynamic.sed" {} +

  if grep -rqE 'e1e21[0-9a-f]|225[,;]226[,;]' "$dir"; then
    echo "dynamic theme: some colors weren't replaced" >&2
    exit 1
  fi

  accent=$(gnome_accent "$(jq -r .accent <<<"$palette")")
  tmp=$(mktemp)
  jq --arg accent "'$accent'" --arg wallpaper "$wallpaper" \
    '.gtk["accent-color"] = $accent | .wallpaper = $wallpaper' "$dir/theme.json" >"$tmp"
  mv -f "$tmp" "$dir/theme.json"
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
  [ "$1" = dynamic ] && render_dynamic
  dir=$(theme_dir "$1")
  if [ -z "$1" ] || [ ! -f "$dir/theme.json" ]; then
    echo "unknown theme: $1 (available: $(names | tr '\n' ' '))" >&2
    exit 1
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
  mapfile -t list < <(names)
  now=$(current)
  index=0
  for i in "${!list[@]}"; do
    [ "${list[i]}" = "$now" ] && index=$i
  done
  apply "${list[(index + $1 + ${#list[@]}) % ${#list[@]}]}"
}

wallpaper() {
  file=$(realpath -e "$1")
  mkdir -p "$state"
  echo "$file" >"$state/wallpaper"
  awww img --transition-type fade --transition-duration 1 "$file" || true
  if [ "$(current)" = dynamic ]; then
    apply dynamic
  fi
}

case "${1:-current}" in
  current) current ;;
  list) names ;;
  set) apply "${2:-}" ;;
  next) step 1 ;;
  prev) step -1 ;;
  apply) apply "$(current)" ;;
  reload) THEME_DIR=$(theme_dir "$(current)") "$reload_hooks" ;;
  wallpaper)
    [ -n "${2:-}" ] || usage
    wallpaper "$2"
    ;;
  *) usage ;;
esac
