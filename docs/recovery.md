# Recovery and bootloader entry

## Important distinction

The WB32 ROM bootloader is stored in MCU system memory, separately from the application firmware. Replacing QMK or Glorious application firmware does not normally overwrite this ROM bootloader.

That makes a bad application flash recoverable **if the board can still be placed into `342D:DFA0` DFU mode**. It is not a promise that every hardware or flashing failure is recoverable.

## Bootloader entry methods

### From this QMK keymap

Press `Fn+Backslash`.

### From confirmed Rev2 stock firmware

Unplug USB, hold `Space+B`, reconnect while holding for five seconds, then release.

### Physical PCB reset/boot control

QMK's board documentation identifies a physical switch on the bottom PCB near the USB daughterboard connection. Access requires opening the case. Follow appropriate ESD precautions and disconnect power before disassembly.

After any method, verify:

```text
USB\VID_342D&PID_DFA0
WB Device in DFU Mode
```

Do not flash when this exact identity is absent.

## Preparing official stock recovery

Run:

```powershell
.\scripts\download-stock-recovery.ps1
```

The script queries Glorious's live CORE manifest for product ID `GMMKPROANSIALT`, downloads the official package, and records its SHA-256. It does not execute the updater.

At the time this guide was tested, the manifest supplied version `0008` from:

```text
https://nyc3.digitaloceanspaces.com/gloriouscore/Glorious_Core/1.0.3_v0008_20220525_GMMK_Pro_WB_Firmware.zip
```

The tested ZIP SHA-256 was:

```text
0107CF197899F0DF48A6C3F76E8FA1FEB39BF33A5D2A2ACF57564B8E0249A332
```

Glorious may update its manifest. Review the resolved product ID, version, URL, and checksum before running any included executable.

## When to stop

Stop instead of trying random firmware when:

- The bootloader is not `342D:DFA0`
- The original stock ID was not `320F:5092`
- The layout is ISO
- The device is a GMMK 3 or HE model
- Windows repeatedly disconnects the bootloader during an attempted write
- Physical damage, liquid exposure, or unstable USB power is suspected
