[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $env:APPDATA 'OpenRGB\OpenRGB.json'),
    [string]$OpenRGBExe = 'C:\Program Files\OpenRGB\OpenRGB.exe',
    [switch]$NoRestart
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "OpenRGB configuration not found at $ConfigPath. Run OpenRGB once, close it, and retry."
}

if (-not $NoRestart) {
    Get-Process OpenRGB -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500
}

$text = Get-Content -LiteralPath $ConfigPath -Raw
if ($text -match '"usb_pid"\s*:\s*"5044"' -and $text -match '"usb_vid"\s*:\s*"320F"') {
    Write-Host 'OpenRGB already contains the 320F:5044 QMK registration.' -ForegroundColor Green
} else {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$ConfigPath.backup-$stamp"
    Copy-Item -LiteralPath $ConfigPath -Destination $backup

    $entry = @'
            {
                "name": "GMMK Pro Rev2 ANSI",
                "usb_pid": "5044",
                "usb_vid": "320F"
            }
'@

    $sectionPattern = '(?s)("QMKOpenRGBDevices"\s*:\s*\{\s*"devices"\s*:\s*\[)(.*?)(\]\s*\})'
    $match = [regex]::Match($text, $sectionPattern)
    if ($match.Success) {
        $current = $match.Groups[2].Value
        $separator = if ([string]::IsNullOrWhiteSpace($current)) { '' } else { ',' }
        $replacement = $match.Groups[1].Value + "`r`n" + $entry + $separator + $current + $match.Groups[3].Value
        $text = $text.Substring(0, $match.Index) + $replacement + $text.Substring($match.Index + $match.Length)
    } else {
        $newSection = @'
    "QMKOpenRGBDevices": {
        "devices": [
            {
                "name": "GMMK Pro Rev2 ANSI",
                "usb_pid": "5044",
                "usb_vid": "320F"
            }
        ]
    },
'@
        if ($text -notmatch '(?m)^\s*"Theme"\s*:') {
            throw 'Could not find a safe insertion point in OpenRGB.json. The backup was not modified.'
        }
        $text = [regex]::Replace($text, '(?m)^(\s*"Theme"\s*:)', $newSection + '$1', 1)
    }

    Set-Content -LiteralPath $ConfigPath -Value $text -Encoding UTF8
    Write-Host "Added OpenRGB QMK registration. Backup: $backup" -ForegroundColor Green
}

if (-not $NoRestart -and (Test-Path -LiteralPath $OpenRGBExe)) {
    Start-Process -FilePath $OpenRGBExe
    Write-Host 'OpenRGB restarted. Rescan devices if the keyboard is not immediately visible.'
}
