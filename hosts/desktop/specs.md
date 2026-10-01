# desktop

Hardware of the `desktop` host, read over SSH from the running system on
2026-10-01 (then still on the pre-refactor `main` configuration).

## Overview

| Part | Model |
| --- | --- |
| Motherboard | MSI B650 GAMING PLUS WIFI (MS-7E26), AM5 |
| CPU | AMD Ryzen 7 7700X (Zen 4, Raphael), 8 cores / 16 threads |
| GPU | NVIDIA GeForce RTX 3070 Ti, 8 GB GDDR6X |
| iGPU | AMD Radeon (Raphael, 1002:164e), not used for display |
| Memory | 32 GB DDR5-6000 (2 × 16 GB Corsair Vengeance, EXPO) |
| Storage | Crucial P3 2 TB NVMe; Kingston A400 240 GB SATA (unused) |
| Displays | ASUS VG249 (1920×1080, 144 Hz), Philips 190C (1280×1024, 75 Hz) |
| Ethernet | Realtek RTL8125, 2.5 Gbit (in use) |
| Wi-Fi / Bluetooth | MediaTek MT7922 (Wi-Fi 6E disabled, Bluetooth on) |
| Firmware | AMI UEFI, BIOS 1.80 (2023-12-15), Secure Boot off, TPM 2.0 |

## CPU

| | |
| --- | --- |
| Cores | 8 Zen 4 cores, SMT (CPUs 0-15) |
| Clocks | 0.4-5.58 GHz |
| Cache | L1d 256 KiB, L1i 256 KiB, L2 8 MiB, L3 32 MiB |
| ISA | AVX2, AVX-512, SHA-NI, SVM (AMD-V) |
| Microcode | 0xa60120a |
| Driver | `amd-pstate-epp` active mode |

## Graphics

| | NVIDIA | AMD iGPU |
| --- | --- | --- |
| PCI | 01:00.0 (`PCI:1:0:0`), card1 | 10:00.0 (`PCI:16:0:0` in NixOS's decimal notation), card2 |
| Driver | nvidia 595.99, open kernel module | amdgpu |
| Role | drives both monitors; Hyprland renders on it | idle, no monitor attached |
| Power | 320 W default limit (366 W max), about 21 W at idle (P8) | |
| Link | PCIe 4.0 x16, Resizable BAR on (8 GB BAR1) | |
| VBIOS | 94.02.B4.00.A4 | |

The desktop RTX 3070 Ti supports neither runtime D3 (the driver reports "Not
supported") nor Dynamic Boost (`nvidia-powerd` exits with "unsupported
system"); both are laptop features, so the config doesn't enable PRIME
offload, fine-grained power management or Dynamic Boost here.

## Displays

| Output | Monitor | Mode | VRR range (EDID) |
| --- | --- | --- | --- |
| HDMI-A-3 | ASUS VG249 (2021), 53 × 30 cm | 1920×1080 at 144 Hz | 48-144 Hz, FreeSync over HDMI |
| HDMI-A-2 | Philips 190C (2007), 38 × 30 cm | 1280×1024 at 75 Hz | 56-76 Hz |

Both are connected to the NVIDIA card over HDMI. NVIDIA doesn't support
FreeSync over HDMI, so the VG249 needs DisplayPort for VRR (G-SYNC
Compatible).

## Memory

| | |
| --- | --- |
| Modules | 2 × Corsair CMK32GX5M2B6000C30, 16 GB DDR5, single rank |
| Speed | 6000 MT/s with EXPO (JEDEC 4800) |
| Slots | 4; DIMMA2 and DIMMB2 used |

## Storage

| Device | Partition | Size | Filesystem | Label | Mount |
| --- | --- | --- | --- | --- | --- |
| Crucial P3 (CT2000P3PSSD8), DRAM-less QLC | nvme0n1p1 | 486 GB | btrfs | HOME | not mounted |
| | nvme0n1p2 | 2 GB | swap | SWAP | swap |
| | nvme0n1p3 | 200 GB | btrfs | ROOT | not mounted |
| | nvme0n1p4 | 512 MB | vfat | BOOTEFI | `/boot` |
| | nvme0n1p5 | 324 GB | btrfs | DATA | `/data` (automounted) |
| | nvme0n1p6 | 300 GB | ext4 | NIXOS | `/` |
| Kingston A400 (SA400S37240G), SATA | sda1-3 | 240 GB | vfat, btrfs, swap | | not mounted |

About 690 GB on the NVMe drive and the whole SATA drive hold partitions
NixOS doesn't mount, apparently from an earlier install. `/` is 72% full.

## Connectivity and devices

| Device | ID / driver |
| --- | --- |
| Ethernet | Realtek RTL8125 2.5GbE, 10ec:8125, `r8169`, `enp12s0` |
| Wi-Fi | MediaTek MT7922, 14c3:0616, `mt7921e` blacklisted |
| Bluetooth | MediaTek MT7922 (USB) |
| USB | AMD 600-series chipset USB 3.2 and Raphael USB 3.1/2.0 controllers |
| SATA | AMD 600-series chipset controller |
| Audio | Realtek ALC897 (board audio), NVIDIA and AMD HDMI audio |

Sensors: CPU (`k10temp`), iGPU, NVMe, memory (`spd5118`), Wi-Fi, ethernet
PHY. The mainline `nct6775` driver finds no Super I/O chip; MSI's AM5 boards
use a Nuvoton NCT6687, so the config loads the out-of-tree `nct6687` driver
for fan speeds and voltages.

## Boot

Firmware 13.1 s, loader 0.6 s, kernel 2.7 s, initrd 3.4 s, userspace 4.3 s:
24.1 s total. Firmware time is mostly DDR5 memory training.
