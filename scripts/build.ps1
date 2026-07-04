[CmdletBinding()]
param(
    [string]$BuildRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build'),
    [string]$QmkMsysBash = 'C:\QMK_MSYS\usr\bin\bash.exe'
)

$ErrorActionPreference = 'Stop'
$QmkCommit = 'cf93bbb78fe0bbf994663555de41372c4b5e59fe'
$ModuleCommit = '529b5f9eb55bea01abe6031d3d8480af826ff247'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$QmkRoot = Join-Path $BuildRoot 'qmk_firmware'
$ModuleRoot = Join-Path $QmkRoot 'modules\openrgb'
$KeymapRoot = Join-Path $QmkRoot 'keyboards\gmmk\pro\rev2\ansi\keymaps\openrgb_rev_e'
$Artifacts = Join-Path $RepoRoot 'artifacts'

function Convert-ToMsysPath([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') {
        throw "Cannot convert path to MSYS format: $full"
    }
    return '/' + $Matches[1].ToLowerInvariant() + '/' + ($Matches[2] -replace '\\', '/')
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git for Windows is required: https://git-scm.com/download/win'
}
if (-not (Test-Path -LiteralPath $QmkMsysBash)) {
    throw "QMK MSYS was not found at $QmkMsysBash. Install it from https://msys.qmk.fm/"
}

$qmkCliCandidates = @(
    (Join-Path $env:USERPROFILE '.local\bin\qmk.exe'),
    'C:\QMK_MSYS\mingw64\bin\qmk.exe',
    'C:\QMK_MSYS\usr\local\bin\qmk.exe'
)
$qmkCli = $qmkCliCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $qmkCli) {
    throw 'The QMK CLI was not found. Open QMK MSYS and run: qmk setup'
}
$msysQmkCliDir = Convert-ToMsysPath (Split-Path $qmkCli -Parent)

New-Item -ItemType Directory -Force -Path $BuildRoot, $Artifacts | Out-Null

if (-not (Test-Path (Join-Path $QmkRoot '.git'))) {
    git clone --filter=blob:none --no-checkout https://github.com/qmk/qmk_firmware.git $QmkRoot
    if ($LASTEXITCODE) { throw 'Failed to clone QMK firmware.' }
}
git -C $QmkRoot fetch origin $QmkCommit --no-tags --no-recurse-submodules
if ($LASTEXITCODE) { throw 'Failed to fetch QMK firmware.' }
git -C $QmkRoot checkout --detach $QmkCommit
if ($LASTEXITCODE) { throw 'Failed to check out the pinned QMK commit. Check for local modifications.' }
git -C $QmkRoot submodule update --init --recursive
if ($LASTEXITCODE) { throw 'Failed to initialize QMK submodules.' }

if (-not (Test-Path (Join-Path $ModuleRoot '.git'))) {
    if (Test-Path $ModuleRoot) { Remove-Item -LiteralPath $ModuleRoot -Recurse -Force }
    git clone --branch module_revE https://gitlab.com/OpenRGBDevelopers/QMK-OpenRGB.git $ModuleRoot
    if ($LASTEXITCODE) { throw 'Failed to clone the OpenRGB QMK module.' }
}
git -C $ModuleRoot fetch origin $ModuleCommit --no-tags --no-recurse-submodules
if ($LASTEXITCODE) { throw 'Failed to fetch the OpenRGB QMK module.' }
git -C $ModuleRoot checkout --detach $ModuleCommit
if ($LASTEXITCODE) { throw 'Failed to check out the pinned OpenRGB module commit.' }

$DefaultKeymap = Join-Path $QmkRoot 'keyboards\gmmk\pro\rev2\ansi\keymaps\default'
if (Test-Path $KeymapRoot) { Remove-Item -LiteralPath $KeymapRoot -Recurse -Force }
Copy-Item -LiteralPath $DefaultKeymap -Destination $KeymapRoot -Recurse
Copy-Item -LiteralPath (Join-Path $RepoRoot 'firmware\keymap.json') -Destination $KeymapRoot -Force

$msysQmkRoot = Convert-ToMsysPath $QmkRoot
$command = "export PATH='${msysQmkCliDir}:/opt/qmk/bin:/mingw64/bin:/usr/bin':`$PATH; cd '$msysQmkRoot' && make gmmk/pro/rev2/ansi:openrgb_rev_e"
& $QmkMsysBash -lc $command
if ($LASTEXITCODE) { throw "QMK build failed with exit code $LASTEXITCODE." }

$BuiltBin = Join-Path $QmkRoot 'gmmk_pro_rev2_ansi_openrgb_rev_e.bin'
if (-not (Test-Path $BuiltBin)) { throw "Build completed but binary was not found: $BuiltBin" }

$OutputBin = Join-Path $Artifacts 'gmmk_pro_rev2_ansi_openrgb.bin'
Copy-Item -LiteralPath $BuiltBin -Destination $OutputBin -Force
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutputBin).Hash
$metadata = @"
Target: gmmk/pro/rev2/ansi
Keymap: openrgb_rev_e
QMK commit: $QmkCommit
OpenRGB module branch: module_revE
OpenRGB module commit: $ModuleCommit
Binary: $OutputBin
SHA-256: $hash
Built UTC: $([DateTime]::UtcNow.ToString('o'))
"@
Set-Content -LiteralPath (Join-Path $Artifacts 'BUILD_INFO.txt') -Value $metadata -Encoding UTF8

Write-Host "`nCompile-only build complete." -ForegroundColor Green
Write-Host "Binary: $OutputBin"
Write-Host "SHA-256: $hash"
Write-Host 'Nothing was flashed.'
