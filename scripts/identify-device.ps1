[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$known = [ordered]@{
    'VID_320F&PID_5092' = [pscustomobject]@{
        State = 'Glorious stock firmware'
        Meaning = 'Confirmed GMMK Pro Rev2 ANSI / WestBerry variant'
        Safe = $true
    }
    'VID_342D&PID_DFA0' = [pscustomobject]@{
        State = 'WB32 ROM DFU bootloader'
        Meaning = 'Exact bootloader required by flash.ps1'
        Safe = $true
    }
    'VID_320F&PID_5044' = [pscustomobject]@{
        State = 'QMK firmware'
        Meaning = 'Expected identity after this build boots'
        Safe = $true
    }
    'VID_320F&PID_B00F' = [pscustomobject]@{
        State = 'Glorious updater mode'
        Meaning = 'Not the WB32 ROM bootloader used by this flasher'
        Safe = $false
    }
}

$devices = Get-PnpDevice -PresentOnly | Where-Object {
    $_.InstanceId -match 'VID_320F|VID_342D'
} | Select-Object Status, Class, FriendlyName, InstanceId

if (-not $devices) {
    Write-Warning 'No matching GMMK/WB32 USB device is currently visible.'
    exit 1
}

$devices | Sort-Object InstanceId | Format-Table -AutoSize -Wrap

$found = @()
foreach ($id in $known.Keys) {
    if ($devices.InstanceId -match [regex]::Escape($id)) {
        $found += $id
        $info = $known[$id]
        Write-Host "`n$id  $($info.State)" -ForegroundColor Cyan
        Write-Host $info.Meaning
        if (-not $info.Safe) {
            Write-Warning 'Do not use this identity as authorization to run flash.ps1.'
        }
    }
}

if (-not $found) {
    Write-Warning 'A related USB device was found, but its identity is not supported by this repository.'
    exit 2
}
