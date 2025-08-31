Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-FullPath([string]$p) {
    if ([System.IO.Path]::IsPathRooted($p)) { return (Resolve-Path -LiteralPath $p).Path }
    return (Resolve-Path -LiteralPath (Join-Path -Path (Get-Location) -ChildPath $p)).Path
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error 'ffmpeg not found in PATH. Please install ffmpeg and ensure it is on PATH.'
}

# Simple argv parser: <source> [m4a|mp3|opus|flac] [<bitrate e.g. 192k>] [-outdir <dir>]
if ($args.Count -lt 1) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  pwsh -File ffmpeg-convert-audio.ps1 <source> [m4a|mp3|opus|flac] [<bitrate e.g. 192k>] [-outdir <dir>]"
    exit 64
}

$Source  = $args[0]
$Format  = 'm4a'
$Bitrate = '192k'
$OutDir  = $null

$validFormats = @('m4a','mp3','opus','flac')

for ($i = 1; $i -lt $args.Count; $i++) {
    $tok = [string]$args[$i]
    if ($validFormats -contains $tok.ToLowerInvariant()) {
        $Format = $tok.ToLowerInvariant(); continue
    }
    if ($tok -match '^[0-9]{2,3}k$') { $Bitrate = $tok; continue }
    if ($tok -ieq '-outdir' -or $tok -ieq '-o') {
        if ($i + 1 -lt $args.Count) { $OutDir = [string]$args[$i+1]; $i++; continue }
        else { Write-Error '-outdir requires a value'; }
    }
}

$inPath = Resolve-FullPath $Source
if (-not (Test-Path -LiteralPath $inPath)) {
    Write-Error "Input file not found: $Source"
}

$inDir = [System.IO.Path]::GetDirectoryName($inPath)
$base  = [System.IO.Path]::GetFileNameWithoutExtension($inPath)
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = $inDir }
else { $OutDir = Resolve-FullPath $OutDir }

if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

switch ($Format) {
    'm4a'  { $ext = 'm4a';  $codecArgs = @('-c:a','aac','-b:a',$Bitrate) }
    'mp3'  { $ext = 'mp3';  $codecArgs = @('-c:a','libmp3lame','-b:a',$Bitrate) }
    'opus' { $ext = 'opus'; $codecArgs = @('-c:a','libopus','-b:a',$Bitrate,'-vbr','on') }
    'flac' { $ext = 'flac'; $codecArgs = @('-c:a','flac','-compression_level','5') }
}

$outPath = Join-Path -Path $OutDir -ChildPath ("$base.$ext")

# Build ffmpeg arguments
$ffArgs = @(
    '-y',
    '-i', $inPath,
    '-vn'
)

$ffArgs += $codecArgs
$ffArgs += @('-map_metadata','0')

# Faststart for m4a/mp4 family
if ($Format -eq 'm4a') { $ffArgs += @('-movflags','+faststart') }

$ffArgs += @($outPath)

Write-Host "Running: ffmpeg $($ffArgs -join ' ')"

& ffmpeg @ffArgs

if ($LASTEXITCODE -ne 0) {
    throw "ffmpeg failed with exit code $LASTEXITCODE"
}

Write-Host "Converted: $outPath"