[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$Firmware = (Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts\gmmk_pro_rev2_ansi_openrgb.bin'),
    [string]$QmkMsysBash = 'C:\QMK_MSYS\usr\bin\bash.exe'
)

$ErrorActionPreference = 'Stop'

function Convert-ToMsysPath([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw "Cannot convert path: $full" }
    return '/' + $Matches[1].ToLowerInvariant() + '/' + ($Matches[2] -replace '\\', '/')
}

if (-not (Test-Path -LiteralPath $Firmware)) { throw "Firmware binary not found: $Firmware" }
if ([System.IO.Path]::GetExtension($Firmware) -ne '.bin') { throw 'Only a QMK .bin file is accepted.' }
if (-not (Test-Path -LiteralPath $QmkMsysBash)) { throw "QMK MSYS not found: $QmkMsysBash" }

$dfu = @(Get-PnpDevice -PresentOnly | Where-Object {
    $_.InstanceId -like 'USB\VID_342D&PID_DFA0\*'
})

if ($dfu.Count -ne 1) {
    throw "Expected exactly one WB32 ROM bootloader (342D:DFA0); found $($dfu.Count). Nothing was written."
}

$service = Get-PnpDeviceProperty -InstanceId $dfu[0].InstanceId -KeyName 'DEVPKEY_Device_Service' -ErrorAction SilentlyContinue
if ($service.Data -ne 'WinUSB') {
    throw "The WB32 bootloader is present but its driver is '$($service.Data)', not WinUSB. Install QMK's WB32 driver first."
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Firmware).Hash
Write-Host 'Verified bootloader: 342D:DFA0 / WinUSB' -ForegroundColor Green
Write-Host "Firmware: $Firmware"
Write-Host "SHA-256: $hash"

if ($PSCmdlet.ShouldProcess('WB32F3G71 flash at 0x08000000', "Write and reset $Firmware")) {
    $msysFirmware = Convert-ToMsysPath $Firmware
    $command = "export PATH='/opt/qmk/bin:/mingw64/bin:/usr/bin':`$PATH; wb32-dfu-updater_cli -l && wb32-dfu-updater_cli -D '$msysFirmware' && wb32-dfu-updater_cli -R"
    & $QmkMsysBash -lc $command
    if ($LASTEXITCODE) { throw "Flasher failed with exit code $LASTEXITCODE. Do not unplug until device state is checked." }

    Start-Sleep -Seconds 3
    $qmk = @(Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match 'VID_320F&PID_5044' })
    if (-not $qmk) {
        Write-Warning 'The write reported success, but 320F:5044 has not enumerated. Check Device Manager before further action.'
        exit 3
    }
    Write-Host 'Flash complete. QMK enumerated as 320F:5044.' -ForegroundColor Green
}
