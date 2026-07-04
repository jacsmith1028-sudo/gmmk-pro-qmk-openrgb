[CmdletBinding()]
param(
    [string]$Destination = (Join-Path (Split-Path $PSScriptRoot -Parent) 'recovery')
)

$ErrorActionPreference = 'Stop'
$manifestUrl = 'https://gloriouscore.nyc3.digitaloceanspaces.com/CORE2/versions-manifest.prod.json'
$productId = 'GMMKPROANSIALT'

Write-Host "Reading Glorious CORE manifest: $manifestUrl"
$manifest = Invoke-RestMethod -Uri $manifestUrl
$entry = @($manifest.Keyboard | Where-Object { $_.productId -eq $productId })
if ($entry.Count -ne 1) {
    throw "Expected one manifest entry for $productId; found $($entry.Count). Nothing was downloaded."
}

$item = $entry[0]
$fileName = [System.IO.Path]::GetFileName(([uri]$item.downloadPath).AbsolutePath)
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$output = Join-Path $Destination $fileName

Write-Host "Product: $($item.name)"
Write-Host "Product ID: $($item.productId)"
Write-Host "Version: $($item.version_device)"
Write-Host "URL: $($item.downloadPath)"
Invoke-WebRequest -Uri $item.downloadPath -OutFile $output
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $output).Hash

$metadata = [ordered]@{
    product = $item.name
    productId = $item.productId
    version = $item.version_device
    url = $item.downloadPath
    file = $output
    sha256 = $hash
    downloadedUtc = [DateTime]::UtcNow.ToString('o')
}
$metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Destination 'RECOVERY_INFO.json') -Encoding UTF8

Write-Host "`nDownloaded official recovery package without executing it." -ForegroundColor Green
Write-Host "File: $output"
Write-Host "SHA-256: $hash"
Write-Warning 'Review docs/recovery.md and reconfirm the hardware identity before running any updater.'
