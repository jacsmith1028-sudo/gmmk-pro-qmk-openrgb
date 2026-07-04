[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$PidFile = Join-Path (Split-Path $PSScriptRoot -Parent) '.runtime\cyberstorm.pid'
$stopped = $false

if (Test-Path -LiteralPath $PidFile) {
    $processId = [int](Get-Content -LiteralPath $PidFile -Raw)
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Id $processId -Force
        $stopped = $true
    }
    Remove-Item -LiteralPath $PidFile -Force
}

Get-CimInstance Win32_Process -Filter "Name = 'python3.exe'" | Where-Object {
    $_.CommandLine -match 'cyberstorm\.py'
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force
    $stopped = $true
}

if ($stopped) {
    Write-Host 'Cyberstorm stopped. The final Direct-mode frame may remain until another mode is selected.' -ForegroundColor Green
} else {
    Write-Host 'Cyberstorm was not running.'
}
