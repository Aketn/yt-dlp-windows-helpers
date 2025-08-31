# Interactive loop to list subtitles for given URL(s)
param(
  [string]$Browser = 'edge'
)
$ErrorActionPreference='Stop'
chcp 65001 > $null

while ($true) {
  $u = Read-Host 'Enter URL (leave empty to exit)'
  if (-not $u) { break }
  ./yt-dlp-run.ps1 -Url $u -Browser $Browser -ListSubs -Playlist
  Write-Host ""
}
