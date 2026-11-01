# Power

Every host has three power profiles (performance, balanced, power-saver),
switched by clicking the battery or profile icon in the bar. The laptop uses
TLP for them, other hosts power-profiles-daemon (`global/power.nix`).

On the laptop (`hosts/laptop/power.nix`), plugging in selects balanced and
unplugging selects power-saver; performance is a manual choice:

| Profile | CPU | Screen and effects |
| --- | --- | --- |
| performance | turbo, performance EPP | 240 Hz, blur, shadows, animations |
| balanced | turbo, balance_performance EPP | 240 Hz, blur, shadows, animations |
| power-saver | no turbo, power EPP, iGPU capped at 900 MHz | 60 Hz, no blur, shadows or animations |

On battery the ethernet controller is unbound and NVIDIA Dynamic Boost is
stopped. The refresh rate and effects come from a user service in
`modules/desktop/hyprland.nix`, so they apply to any host with a laptop panel.

The laptop's NVIDIA GPU stays powered off unless something asks for it
(`modules.hardware.graphics.nvidia.hybrid.offloadOnly`): desktop programs
only see the Intel GPU. Steam, Heroic, Lutris and Prism Launcher run on the
NVIDIA GPU; anything else can with `nvidia-offload <command>`. Check whether
it is powered off with
`cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` (`suspended`).

An external display attached to the NVIDIA GPU at login keeps it awake: the
`start-hyprland` wrapper then gives the compositor the NVIDIA EGL driver so it
can render to that display. Displays plugged in later need a Hyprland restart.

Closing the laptop lid only turns the panel off, so work keeps running.
`Fn + F1` suspends, then hibernates after 30 minutes. Swap is zswap in front
of a 40 GB partition (`modules.performance.swap = "zswap"`), large enough to
hibernate; the desktop keeps zram only.

The laptop's disks are not encrypted yet. LUKS for `ROOT`, `DATA` and the
swap partition is planned; the unallocated space at the end of the disk leaves
room to migrate.

Nix builds use at most `modules.performance.buildThreads` CPU threads (28 of
32 on the laptop, 12 of 16 on the desktop) at batch priority.

## Laptop charge limit (untested)

The firmware has no charge limit Linux can use without a platform driver.
`hosts/laptop/uniwill.nix` builds a copy of the mainline `uniwill-laptop`
driver restricted to this barebone's features; binding it sets the charge mode
to Trickle (stop at 80%). Another reseller's unit of the same chassis kept
charging to 100% in that mode, so test it once, plugged in, above 80%:

```sh
sudo modprobe uniwill_gm6ix force=1
cat /sys/class/power_supply/BAT0/charge_types      # [Trickle] Standard Long Life
cat /sys/class/power_supply/BAT0/{status,current_now}   # not "Charging" above 80%
```

If it keeps charging, `sudo modprobe -r uniwill_gm6ix` and leave it unloaded.
If it stops, add `uniwill_gm6ix` to `boot.kernelModules` with
`boot.extraModprobeConfig = "options uniwill_gm6ix force=1"`. Before a trip,
`echo Standard | sudo tee /sys/class/power_supply/BAT0/charge_types` charges
to 100% until the next boot.
