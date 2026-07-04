# Hardware identification

## Scope

This build targets only:

- Original **GMMK Pro**, not GMMK 3 Pro
- Wired 75% board
- ANSI layout
- Rev2 / WestBerry PCB
- WB32F3G71 MCU

The case label `GMMK PRO` does not identify the PCB revision. Use the USB ID while the board is still on stock firmware.

## Windows check

Run:

```powershell
.\scripts\identify-device.ps1
```

The confirmed stock identity for this guide is:

```text
VID_320F&PID_5092
```

Glorious CORE associates this variant with product ID `GMMKPROANSIALT`. Current QMK exposes it as target `gmmk/pro/rev2/ansi`, with processor `WB32F3G71` and bootloader `wb32-dfu`.

## IDs that must not be treated as equivalent

- A stock `320F:5044` device is not enough evidence of Rev2; that ID is also used by the QMK build after flashing.
- `320F:B00F` is a Glorious updater identity, not the WB32 ROM DFU identity used by QMK's flasher.
- `342D:DFA0` is the WB32 ROM bootloader QMK explicitly recognizes.
- Any GMMK 3, ISO, HE, wireless, or unknown identity is out of scope.

If the board is already running third-party firmware, USB IDs alone may no longer prove the underlying PCB revision. Open the case and inspect the PCB markings, or restore known-correct stock firmware first.
