# laptop

Hardware of the `laptop` host, read from the running system on 2026-10-01,
re-checked against vendor listings on 2026-10-21 and against the case, battery
and adapter labels on 2026-11-03.

## Model

| | |
| --- | --- |
| Retail model | Captiva Advanced Gaming I84-740 (16", i9-14900HX, 32 GB, 2 TB SSD, RTX 4060 8 GB, no OS) |
| Captiva article | Art.-Nr. 84740, EAN 4046373847404 |
| Captiva case code | GB6 946IG 24T1 |
| Barebone | Uniwill GM6IX0B (base label, SMBIOS OEM strings 11-12) |
| Same barebone | TUXEDO Stellaris 16 Gen6 (Intel), XMG NEO 16 (E24) with RTX 4060/4070, Eluktronics Hydroc 16 G1; board family `GM6IXxB` |
| Size and weight | 356.68 × 245.02 × 26.6 mm, 2.6 kg |
| Power input | 20 V, 12 A (base label) |

DMI reports every vendor, product and board field as "Standard"; only the
SMBIOS OEM strings name the barebone (`sudo dmidecode -t 11`). The touchpad's
ACPI ID (`UNIW0001`) and the Uniwill WMI GUIDs agree.

No page for the I84-740 itself was reachable or archived. The case code, size
and weight come from the archived page of the I84-744, the same configuration
with Windows 11 Home
([captiva-power.de, 2025-11-16](https://web.archive.org/web/20251116063413/https://www.captiva-power.de/produkte/nbs/advanced-gaming-i84-744)).
That page disagrees with the hardware in a few places:

| | Captiva page | This unit |
| --- | --- | --- |
| Battery | 80 Wh | 99.9 Wh; the bay and cable also take the 80 Wh pack |
| Wi-Fi | Wi-Fi 6 | Wi-Fi 6E (AX211) |
| Memory speed | DDR5-5200 | DDR5-5600 |
| Maximum memory | 64 GB | 64 GiB per SMBIOS; TUXEDO sells the barebone with up to 96 GB (2 × 48 GB), untested here |

## Overview

| Part | Model |
| --- | --- |
| CPU | Intel Core i9-14900HX (Raptor Lake Refresh) |
| iGPU | Intel UHD Graphics (Raptor Lake-S, 8086:a788) |
| dGPU | NVIDIA GeForce RTX 4060 Laptop GPU, 8 GB |
| Memory | 32 GB DDR5-5600 (2 × 16 GB) |
| Storage | TEAMGROUP TM8FP6002T, 2 TB NVMe |
| Display | BOE NE160QDM-NZA, 16" 2560×1600, 240 Hz |
| Wi-Fi / Bluetooth | Intel Wi-Fi 6E AX211 (CNVi) |
| Ethernet | Motorcomm YT6801, 1 Gbit |
| Battery | Li-polymer 4S1P, 99.9 Wh (PHID1-13-17-4S1P-0) |
| Firmware | AMI Aptio (UEFI 2.80), BIOS N.1.07STD03 (2024-07-11), EC 1.23 |

## CPU

| | |
| --- | --- |
| Cores | 24: 8 P-cores (CPUs 0-15, with Hyper-Threading) and 16 E-cores (CPUs 16-31) |
| Clocks | P-cores up to 5.6 GHz, E-cores up to 4.1 GHz (cpufreq); Intel lists 5.8 GHz max turbo |
| Cache | L1d 896 KiB, L1i 1.3 MiB, L2 32 MiB, L3 36 MiB |
| ISA | AVX2, AVX-VNNI, SHA-NI, VT-x; no AVX-512 |
| Microcode | 0x137 |
| Driver | `intel_pstate` active mode (HWP), uncore frequency 0.8-5.0 GHz |

The HX parts use the desktop Raptor Lake-S die, so idle power is higher than on
H/U laptop chips: the package idles at about 7 W on battery settings.

## Graphics

| | Intel iGPU | NVIDIA dGPU |
| --- | --- | --- |
| PCI | 00:02.0 (`PCI:0:2:0`), card1 | 01:00.0 (`PCI:1:0:0`), card0 |
| Driver | i915 (Mesa) | nvidia 595.104.02, open kernel module |
| Clocks / memory | 300-1650 MHz | 8 GB GDDR6, PCIe 4.0 x8, 140 W max |
| VBIOS | | 95.07.3F.00.26 |
| Role | drives the internal panel, renders the desktop | PRIME offload only (games, `nvidia-offload`); powered off otherwise |
| Outputs | `eDP-1` (internal panel) | `HDMI-A-1`, `DP-1`, `DP-2`, `eDP-2` |

The NVIDIA HDMI audio function (01:00.1) is removed at boot so the dGPU can
reach D3cold. Check with
`cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` (`suspended`).

Every external display output hangs off the NVIDIA GPU: HDMI, the DisplayPort
output and the Thunderbolt port's DP alt mode (Captiva lists DP 1.4). Which of
`DP-1`/`DP-2` is which hasn't been checked. Plugging in a monitor wakes the
dGPU and keeps it out of D3cold. `eDP-2` is the panel's second path through
the display MUX (Captiva lists NVIDIA Advanced Optimus); it stays disconnected
while the iGPU drives the panel.

## Display

| | |
| --- | --- |
| Panel | BOE NE160QDM-NZA (EDID model 0x0B87, made 2022) |
| Size | 345 × 215 mm, 16:10, 8-bit RGB |
| Modes | 2560×1600 at 60, 144 and 240 Hz |
| VRR | 60-240 Hz |
| Panel Self Refresh | not supported (kernel reports `PSR = no`) |

Without PSR the display engine never reaches its DC5/DC6 low-power states,
which is part of the idle power floor. Hyprland uses scale 1.33.

## Memory

| | |
| --- | --- |
| Modules | 2 × Kingston 9905790-210.A00G, 16 GB DDR5 SODIMM, single rank |
| Speed | 5600 MT/s (configured 5600) |
| Slots | 2, both used; 64 GiB maximum per SMBIOS |
| Swap | zswap (zstd, 20% pool) in front of `nvme0n1p2` 40 GB; hibernation resumes from it |

## Storage

TEAMGROUP TM8FP6002T: MAXIO MAP1202 DRAM-less controller (1e4b:1202), firmware
SN24998, 2.05 TB.

| Partition | Size | Filesystem | Label | Mount |
| --- | --- | --- | --- | --- |
| nvme0n1p3 | 512 MB | vfat | | `/boot` |
| unallocated | 7.5 GB | | | |
| nvme0n1p1 | 800 GB | ext4 | ROOT | `/` |
| nvme0n1p4 | 500 GB | ext4 | DATA | `/data` (automounted) |
| nvme0n1p2 | 40 GB | swap | SWAP | |
| unallocated | 560 GB | | | |

Rows are in disk order. A GPT backup from before the swap move (2026-10-27) is
at `~/.local/state/gpt-nvme0n1-20261027.bin`.

NVMe power states: PS0-PS2 operational (6.5 / 5.8 / 3.6 W max), PS3 0.05 W
(15 ms round trip), PS4 0.005 W (53 ms). APST needs the kernel's default
latency limit to use PS3/PS4; a limit below 15000 µs keeps the drive awake.

## Connectivity

| Device | ID | Notes |
| --- | --- | --- |
| Wi-Fi | Intel AX211 CNVi, 8086:7a70 | Wi-Fi 6E, 160 MHz, `iwlwifi` firmware 89 |
| Bluetooth | Intel AX211, 8087:0033 (USB) | off at boot |
| Ethernet | Motorcomm YT6801, 1f0a:6801, 3a:00.0 | out-of-tree `yt6801` module; no ASPM, unbound on battery |
| Thunderbolt 4 | Intel Maple Ridge 2C (8086:1133/1134/1135) | USB4 host; the one UCSI port, accepts USB-C PD charging |
| USB | Intel 700-series xHCI (USB 3.2 Gen 2x2), two Genesys hubs (05e3:0610, 05e3:0620) | |
| Card reader | Realtek 0bda:0316 (USB 3) | shows up as `sda` |

Ports per Captiva: 3 × USB-A 3.2 Gen 1, 1 × USB-C 3.2 Gen 2, 1 × Thunderbolt 4
(USB-C with PD and DP 1.4), HDMI, DisplayPort, RJ-45, card reader, 3.5 mm
combo jack, DC-in and a Kensington slot.

## Input, audio and other devices

| Device | ID / driver |
| --- | --- |
| Keyboard | PS/2 (i8042, "AT Translated Set 2 keyboard") |
| Keyboard lighting | ITE 8291, 048d:600b, single-zone RGB (`ite_8291` blacklisted) |
| Lightbar | ITE 8233, 048d:7001, LED `rgb:lightbar` |
| Touchpad | PixArt 093A:0255 on I2C HID `UNIW0001:00` |
| Webcam | Kingcome FHD WebCam, 2b7e:c858 |
| Audio | Intel 700-series HDA; Conexant SN6140 codec, Intel HDMI codec; two speakers |
| TPM | TPM 2.0 (MSFT0101) |
| Chipset | Intel HM770 |

Sensors: CPU (`coretemp`), NVMe, memory modules (`spd5118`), ACPI thermal
zones, Wi-Fi. Fan speeds aren't exposed (see Platform drivers).

## Platform drivers

`tuxedo-drivers` and the mainline `uniwill-laptop` driver (in the running 7.2
kernel) both support this board as `GM6IXxB_MB1`/`GM6IXxB_MB2`, but they match
on DMI vendor `TUXEDO` and that board name. This firmware reports "Standard",
so neither binds: charge limits, fan readings, fan control and TDP limits stay
unavailable, and `tuxedo-keyboard` fails its compatibility check. The lightbar
works because `ite_8291_lb` matches by USB ID.
The Uniwill/Clevo WMI modules that the board's GUIDs would autoload, and the
unused ASUS and `xe` drivers, are blacklisted in `hardware.nix`.

`uniwill-laptop` takes `force=1` to skip the DMI check, but then enables every
feature, including EC writes for hardware this board lacks. `uniwill.nix`
builds a copy (`uniwill_gm6ix`) that uses TUXEDO's GM6IXxB feature set
instead: charge modes (80/90/100%), fan and temperature sensors, NVIDIA
cTGP. It isn't loaded automatically; on an Eluktronics unit of the same
chassis the EC accepted the charge mode but kept charging to 100%
([tongfang-uniwill-dkms](https://github.com/arbitrary-string/tongfang-uniwill-dkms)).

## Battery

| | |
| --- | --- |
| Pack | PHID1-13-17-4S1P-0, Uniwill part BATRPHID13-4104, made 2024-08-14 by HuiZhou GanFeng LiEnergy |
| Cells | Li-polymer, 4 in series (4ICP5/63/128) |
| Rating | 15.48 V; 6450 mAh / 99.9 Wh typical, 6300 mAh / 97.6 Wh rated; 17.8 V charge limit |
| Cable | CABRG6B261-5301, labelled `BATTERY,GM6IX0B,60/80W`; the pack plugs into it, not into the board |
| Design capacity | 6400 mAh, 99.1 Wh (EC) |
| Current full charge | 4500 mAh, 69.7 Wh: 70% of design (2026-11-03; 66% on 2026-10-21) |
| Cycle count | not reported (EC returns 0) |
| Charge limits | charge modes via `uniwill_gm6ix`, untested (see Platform drivers) |

The EC ends every charge at about 16.75 V (4.19 V per cell, peak 16.77 V in
upower's history since 2026-10-27), not at the 17.8 V on the label, and then
reports 100%. Cells rated to 4.45 V hold about 15-20% more above 4.2 V, so the
70% figure probably under-reads the pack (unconfirmed). To check, bind
`uniwill_gm6ix`, set `Standard` (see `docs/power.md`) and charge once: a
voltage above 17 V and a larger full charge mean the pack is healthier than
reported.

## Power supply

| | |
| --- | --- |
| Adapter | FSP Group FSP240-ACBU3, part AICR010240-2004, 20 V 12 A, 240 W |
| DC plug | barrel 5.5/2.5 mm, 12.5 mm long (`AC0`) |
| Mains inlet | IEC C6; takes a C5 (cloverleaf) cord |
| USB-C | Thunderbolt port, USB PD at 20 V / 5 A (100 W) only; CPU and GPU throttle |

USB-C charging needs a 5 A (e-marked) cable; chargers below 100 W don't
charge it.

Power profiles and what they change are documented in `power.nix` and
`docs/power.md`.

## Firmware

| | |
| --- | --- |
| BIOS | AMI Aptio, N.1.07STD03 (2024-07-11), release 5.27 |
| EC | 1.23 |
| CPU microcode | 0x120 in the BIOS; Linux loads 0x137 early |
| Secure Boot | disabled |

fwupd (LVFS) offers nothing for this machine except Microsoft's UEFI dbx,
which only matters with Secure Boot on (checked 2026-10-27). Captiva publishes
no BIOS or EC updates. XMG's newest image for the same board, N1.07A08
(2024-11-12), has the same BIOS line and EC 1.23
([XMG downloads, archived](https://web.archive.org/web/20250714092222/https://download.schenker-tech.de/package/xmg-neo-16-17-e24-xne16e24-xne17e24/)).
