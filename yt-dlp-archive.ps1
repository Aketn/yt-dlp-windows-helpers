# Append to archive.txt after successful download
param(
    [Parameter(Mandatory=$false)][string]$Archive = "archive.txt"
)

$ErrorActionPreference = 'Stop'
$yt = Join-Path $PSScriptRoot 'yt-dlp.exe'
if (-not (Test-Path $yt)) { $yt = 'yt-dlp' }

$cmd = @(
    $yt,
    '--download-archive', $Archive
)

Write-Host "Archive arg helper: --download-archive $Archive" -ForegroundColor Green
