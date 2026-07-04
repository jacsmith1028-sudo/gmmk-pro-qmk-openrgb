# GMMK Pro Rev2 ANSI: QMK + OpenRGB

A reproducible Windows guide for building and flashing OpenRGB-enabled QMK firmware on the **original wired GMMK Pro 75%, Rev2 (WB32), ANSI layout**.

This repository exists because the model name printed on the case is not enough to choose safe firmware. The scripts check USB identities before any write.

> [!CAUTION]
> Flashing firmware always carries risk. This project is **not** for GMMK Pro Rev1, ISO boards, GMMK 2, GMMK 3, HE, wireless, or other layouts. Never bypass the USB-ID checks because a board looks similar.

## Confirmed hardware identities

| State | USB ID | Meaning |
|---|---|---|
| Glorious stock firmware | `320F:5092` | Original GMMK Pro Rev2 ANSI / WestBerry variant used by this guide |
| WB32 ROM bootloader | `342D:DFA0` | Safe state expected immediately before a QMK flash |
| QMK firmware | `320F:5044` | Expected identity after this build boots |

The ROM bootloader is built into the WB32 MCU and is separate from the firmware being replaced.

## Required software

- Windows 10 or 11
- [Git for Windows](https://git-scm.com/download/win)
- [QMK MSYS](https://msys.qmk.fm/)
- [OpenRGB](https://openrgb.org/)
- PowerShell 5.1 or newer

Run PowerShell as Administrator for device detection and driver operations.

## Quick start

### 1. Identify the connected board

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\identify-device.ps1
```

Continue only when stock firmware reports `320F:5092`. If it reports an unknown ID, stop and investigate the exact PCB revision and layout.

### 2. Build, without flashing

```powershell
.\scripts\build.ps1
```

The script clones pinned QMK and OpenRGB-module commits, copies QMK's default Rev2 ANSI keymap as `openrgb_rev_e`, enables the OpenRGB community module, and outputs a `.bin` under `artifacts\`. It does not access the keyboard.

### 3. Enter the ROM bootloader

From Glorious stock firmware:

1. Unplug the keyboard.
2. Hold `Space+B`.
3. Reconnect USB while holding both keys for about five seconds.
4. Release the keys.
5. Run `.\scripts\identify-device.ps1` again.

It must report `342D:DFA0` as **WB Device in DFU Mode**. If the shortcut does not work, see [Recovery and bootloader entry](docs/recovery.md).

### 4. Dry-run, then flash

```powershell
.\scripts\flash.ps1 -WhatIf
.\scripts\flash.ps1
```

The second command asks for high-impact confirmation and refuses to write unless `342D:DFA0` is present.

Do not unplug the keyboard during writing. A successful reset should enumerate as `320F:5044`.

### 5. Register it in OpenRGB

```powershell
.\scripts\configure-openrgb.ps1
```

Restart or rescan OpenRGB. It should report `GMMK Pro ANSI`, 98 LEDs, a keyboard zone, and an underglow zone.

## Recovery preparation

Download—do not flash—the exact official Glorious recovery package before experimenting:

```powershell
.\scripts\download-stock-recovery.ps1
```

The package is retrieved from Glorious's live CORE manifest and is not redistributed by this repository. Read [recovery.md](docs/recovery.md) before using it.

## What is pinned

- QMK firmware: `cf93bbb78fe0bbf994663555de41372c4b5e59fe`
- OpenRGB QMK community module, `module_revE`: `529b5f9eb55bea01abe6031d3d8480af826ff247`
- QMK target: `gmmk/pro/rev2/ansi`
- MCU/bootloader: `WB32F3G71` / `wb32-dfu`

These are the exact sources used for the tested build. Updating either dependency creates a new, untested combination; review and test compile-only before flashing.

## Documentation

- [Hardware identification](docs/hardware-identification.md)
- [Build and flash details](docs/build-and-flash.md)
- [OpenRGB setup](docs/openrgb.md)
- [Recovery](docs/recovery.md)
- [Troubleshooting](docs/troubleshooting.md)

## Licensing and attribution

The original scripts and documentation in this repository are MIT licensed. QMK firmware and the OpenRGB QMK community module are GPL-licensed upstream projects and are cloned at build time. Their licenses continue to apply to compiled firmware and corresponding source.

Glorious, GMMK, OpenRGB, and QMK are names belonging to their respective owners. This is an independent community project and is not endorsed by Glorious, OpenRGB, or QMK.
