# laptop

Hardware of the `laptop` host, read from the running system on 2026-10-01.
DMI reports every vendor and product field as "Standard"; the touchpad's ACPI
ID (`UNIW0001`) points to a Uniwill-built chassis.

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
| Battery | Li-ion 4S, 99 Wh design (6400 mAh at 15.48 V) |
| Firmware | AMI UEFI 2.80, BIOS N.1.07STD03 (2024-07-11) |

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

The NVIDIA HDMI audio function (01:00.1) is removed at boot so the dGPU can
reach D3cold. Check with
`cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` (`suspended`).

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
| Slots | 2, both used; 64 GB maximum |
| Swap | zram 31 GB (zstd) at priority 100, then `nvme0n1p2` 7.5 GB |

## Storage

TEAMGROUP TM8FP6002T: MAXIO MAP1202 DRAM-less controller (1e4b:1202), firmware
SN24998, 2.05 TB.

| Partition | Size | Filesystem | Label | Mount |
| --- | --- | --- | --- | --- |
| nvme0n1p1 | 800 GB | ext4 | ROOT | `/` |
| nvme0n1p2 | 7.5 GB | swap | SWAP | |
| nvme0n1p3 | 512 MB | vfat | | `/boot` |
| nvme0n1p4 | 500 GB | ext4 | DATA | `/data` (automounted) |
| unallocated | 600 GB | | | |

NVMe power states: PS0-PS2 operational (6.5 / 5.8 / 3.6 W max), PS3 0.05 W
(15 ms round trip), PS4 0.005 W (53 ms). APST needs the kernel's default
latency limit to use PS3/PS4; a limit below 15000 µs keeps the drive awake.

## Connectivity

| Device | ID | Notes |
| --- | --- | --- |
| Wi-Fi | Intel AX211 CNVi, 8086:7a70 | Wi-Fi 6E, 160 MHz, `iwlwifi` firmware 89 |
| Bluetooth | Intel AX211, 8087:0033 (USB) | off at boot |
| Ethernet | Motorcomm YT6801, 1f0a:6801, 3a:00.0 | out-of-tree `yt6801` module; no ASPM, unbound on battery |
| Thunderbolt 4 | Intel Maple Ridge 2C (8086:1133/1134/1135) | USB4 host; UCSI reports one USB-C port |
| USB | Intel 700-series xHCI (USB 3.2 Gen 2x2), two Genesys hubs (05e3:0610, 05e3:0620) | |
| Card reader | Realtek 0bda:0316 (USB 3) | shows up as `sda` |

## Input, audio and other devices

| Device | ID / driver |
| --- | --- |
| Keyboard | PS/2 (i8042, "AT Translated Set 2 keyboard") |
| Keyboard lighting | ITE 8291, 048d:600b (`ite_8291` blacklisted) |
| Lightbar | ITE 8233, 048d:7001, LED `rgb:lightbar` |
| Touchpad | PixArt 093A:0255 on I2C HID `UNIW0001:00` |
| Webcam | Kingcome FHD WebCam, 2b7e:c858 |
| Audio | Intel 700-series HDA; Conexant SN6140 codec, Intel HDMI codec |
| TPM | TPM 2.0 (MSFT0101) |
| Chipset | Intel HM770 |

Sensors: CPU (`coretemp`), NVMe, memory modules (`spd5118`), ACPI thermal
zones, Wi-Fi. Fan speeds aren't exposed.

## Battery and power

| | |
| --- | --- |
| Design capacity | 6400 mAh (about 99 Wh) |
| Current full charge | 4000 mAh (about 62 Wh), 62.5% of design |
| Charge limits | not supported; TLP finds no driver for this chassis |
| Charger | AC adapter (`AC0`) and USB-C power delivery (UCSI) |
| Secure Boot | disabled |

Power profiles and what they change are documented in `power.nix` and the
README's Power section.
