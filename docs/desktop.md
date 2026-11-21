# Desktop

Hyprland with a Quickshell frame around the screen. The left side of the
frame is the bar, top to bottom:

| Item | Hover | Click | Scroll |
| --- | --- | --- | --- |
| Clock | date | | |
| Workspace pills (this monitor) | | switch | step through |
| Brightness (laptops) | percentage | | 5% steps |
| Volume | output and level | left: mute, right: pwvucontrol | 5% steps, up to 150% |
| Network | connection | left: nmtui, right: Wi-Fi on/off | |
| Battery (laptops), power profile icon (desktop) | level, time left, power profile | cycle power profile | |
| Gear (bottom) | current theme | left: next theme, right: previous | |
| Dot in the bottom-right corner | | notes popup | |

Keys beyond the usual window management (`global/home/.config/hypr/hyprland.lua`
and `users/lex/home/.config/hypr/hyprland.lua`):

| Keys | Action |
| --- | --- |
| volume, mute, mic mute, brightness keys | change the value and show the swayosd popup |
| `SUPER + N` | night light on/off; it also follows the schedule in `global/home/.config/hypr/hyprsunset.conf` (4500 K from 21:00 to 07:00) |
| `SUPER + Print` | region screenshot to the clipboard |
| `SUPER + SHIFT + Print` | region screenshot into flameshot for annotation |
