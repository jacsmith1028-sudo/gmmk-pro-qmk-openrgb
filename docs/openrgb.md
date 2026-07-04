# OpenRGB setup

The QMK OpenRGB protocol is unofficial and opt-in. OpenRGB does not probe arbitrary Raw HID devices, so the keyboard must be registered by VID/PID.

Run:

```powershell
.\scripts\configure-openrgb.ps1
```

This adds the following entry to OpenRGB's user configuration:

```json
"QMKOpenRGBDevices": {
    "devices": [
        {
            "name": "GMMK Pro Rev2 ANSI",
            "usb_pid": "5044",
            "usb_vid": "320F"
        }
    ]
}
```

The script backs up the configuration before editing it.

Expected detection:

- Name: `GMMK Pro ANSI`
- Description: QMK OpenRGB Device
- 98 total LEDs
- 16 underglow LEDs
- Keyboard and Underglow zones

If the keyboard is visible to Windows but absent from OpenRGB, check [troubleshooting.md](troubleshooting.md).
