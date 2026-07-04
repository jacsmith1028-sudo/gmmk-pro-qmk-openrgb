# Troubleshooting

## `identify-device.ps1` reports no keyboard

- Connect directly to the PC, not through a hub or KVM.
- Try a known data-capable USB-C cable.
- Check Device Manager for failed USB devices.
- Re-enter the bootloader and rerun the script.

## Bootloader appears as `342D:DFA0`, but flashing cannot open it

QMK expects the WinUSB driver. QMK MSYS can install the driver through its driver installer, or use QMK Toolbox's driver setup. In Device Manager the service should be `WinUSB`.

Do not replace drivers for unrelated USB devices.

## QMK works, but OpenRGB does not list the keyboard

1. Confirm Windows now reports `320F:5044`.
2. Run `scripts/configure-openrgb.ps1`.
3. Exit every OpenRGB process and reopen it.
4. Rescan devices.
5. Run `OpenRGB.exe --list-devices --noautoconnect --loglevel 5 --verbose` and look for the Raw HID interface with usage page `FF60`.

## Keyboard types, but RGB is wrong

- Confirm the build target was exactly `gmmk/pro/rev2/ansi`.
- Confirm the OpenRGB module commit matches the pinned revision.
- Stop other RGB applications that may compete for the same HID interface.
- Return to a built-in QMK mode before closing a software effect if you do not want the final Direct-mode frame to remain displayed.

## `Fn+Backslash` seems to make the keyboard disappear

That shortcut intentionally enters `342D:DFA0` bootloader mode. Unplugging and reconnecting normally exits it without flashing.
