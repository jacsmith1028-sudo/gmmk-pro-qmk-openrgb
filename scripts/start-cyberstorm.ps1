[CmdletBinding()]
param(
    [ValidateRange(1, 60)]
    [int]$Fps = 24,
    [switch]$NoMouse,
    [string]$OpenRGBExe = 'C:\Program Files\OpenRGB\OpenRGB.exe',
    [string]$PythonExe = 'C:\QMK_MSYS\usr\bin\python3.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$Runtime = Join-Path $RepoRoot '.runtime'
$Effect = Join-Path $RepoRoot 'effects\cyberstorm.py'
$Requirements = Join-Path $RepoRoot 'effects\requirements.txt'
$PidFile = Join-Path $Runtime 'cyberstorm.pid'

if (-not (Test-Path -LiteralPath $OpenRGBExe)) {
    throw "OpenRGB not found: $OpenRGBExe"
}
if (-not (Test-Path -LiteralPath $PythonExe)) {
    throw "Python not found at $PythonExe. Installing QMK MSYS provides a compatible Python runtime."
}

New-Item -ItemType Directory -Force -Path $Runtime | Out-Null
if (-not (Test-Path (Join-Path $Runtime 'openrgb'))) {
    & $PythonExe -m pip install --target $Runtime -r $Requirements
    if ($LASTEXITCODE) { throw 'Failed to install the OpenRGB Python SDK client.' }
}

Get-CimInstance Win32_Process -Filter "Name = 'python3.exe'" | Where-Object {
    $_.CommandLine -match 'cyberstorm\.py'
} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Get-Process OpenRGB -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Start-Process -FilePath $OpenRGBExe -ArgumentList '--server', '--startminimized'

$ready = $false
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 250
    try {
        $tcp = [System.Net.Sockets.TcpClient]::new()
        $tcp.Connect('127.0.0.1', 6742)
        $tcp.Close()
        $ready = $true
        break
    } catch {}
}
if (-not $ready) { throw 'OpenRGB SDK server did not open localhost port 6742.' }

function Convert-ToMsysPath([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw "Cannot convert path: $full" }
    return '/' + $Matches[1].ToLowerInvariant() + '/' + ($Matches[2] -replace '\\', '/')
}

$arguments = @((Convert-ToMsysPath $Effect), '--fps', $Fps)
if ($NoMouse) { $arguments += '--no-mouse' }
$process = Start-Process -FilePath $PythonExe -ArgumentList $arguments -WindowStyle Hidden -PassThru
Set-Content -LiteralPath $PidFile -Value $process.Id -Encoding ASCII
Start-Sleep -Seconds 2
$process.Refresh()
if ($process.HasExited) { throw "Cyberstorm exited early with code $($process.ExitCode)." }

Write-Host "Cyberstorm is running at $Fps FPS (PID $($process.Id))." -ForegroundColor Green
if ($NoMouse) { Write-Host 'Mouse synchronization is disabled.' }
