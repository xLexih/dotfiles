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

## Laptop charging

The laptop charges to 100% and has no working charge limit. The EC ends every
charge at about 16.75 V (4.19 V per cell), well below the 17.8 V the pack is
rated for.

`hosts/laptop/uniwill.nix` builds `uniwill_gm6ix`, a copy of the mainline
`uniwill-laptop` driver restricted to this barebone's features. It isn't
loaded automatically: it needs `force=1`, which taints the kernel, and its
charge modes don't change anything here. On 2026-11-03 the EC was in
Standard. A charge from 77% in Trickle (TUXEDO's Stationary) also ended at
16.75 V and reached 100%. TUXEDO units with the same EC charge to a lower
voltage in Stationary
([TCC issue #268](https://github.com/tuxedocomputers/tuxedo-control-center/issues/268)).

At 5% upower hibernates the laptop, which keeps the pack above its cutoff
voltage.
