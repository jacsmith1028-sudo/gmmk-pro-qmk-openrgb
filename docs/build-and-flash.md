# Build and flash details

## Build process

`scripts/build.ps1` performs these actions:

1. Verifies Git and QMK MSYS are installed.
2. Clones QMK at the pinned commit.
3. Clones the OpenRGB QMK community module's `module_revE` branch at the pinned commit.
4. Copies QMK's default `gmmk/pro/rev2/ansi` keymap.
5. Adds `firmware/keymap.json`, enabling the module.
6. Compiles `gmmk/pro/rev2/ansi:openrgb_rev_e`.
7. Copies the binary and build metadata into `artifacts/`.

It never flashes.

## Why the checks matter

The firmware is linked for the WB32F3G71 memory map and for the Rev2 ANSI matrix, RGB chain, pins, oscillator, and bootloader. A successful compile only proves source consistency; it does not prove the connected keyboard matches the target.

`scripts/flash.ps1` therefore requires all of the following:

- A `.bin` produced in this repository's `artifacts/` directory
- Exactly one connected `342D:DFA0` WB32 ROM bootloader
- QMK's `wb32-dfu-updater_cli`
- Interactive high-impact confirmation unless explicitly overridden

## Expected flash output

Key lines are similar to:

```text
Found DFU
Device ID 342d:dfa0
Chip id: 0x3A50A980
Flash size: 128 KBytes
Download block start address: 0x08000000
Writing ...
OK
Download completed!
Reset device completed!
```

After reset, Windows should enumerate `320F:5044` and expose keyboard, consumer-control, mouse, and vendor-defined Raw HID interfaces.

## QMK bootloader shortcut after flashing

The copied default keymap assigns `QK_BOOT` to `Fn+Backslash`. This re-enters the WB32 ROM bootloader without opening the case.
