# PowerShell script to wrap yt-dlp with helpful defaults
# Usage examples:
#   ./yt-dlp-run.ps1 -Url "https://www.youtube.com/watch?v=..." -Format "bestvideo+bestaudio/best" -Browser chrome -OutTemplate "%(title)s [%(id)s].%(ext)s"
#   ./yt-dlp-run.ps1 -UrlFile urls.txt -Playlist true

param(
    [Parameter(Mandatory=$false)][string]$Url,
    [Parameter(Mandatory=$false)][string]$UrlFile,
    [Parameter(Mandatory=$false)][string]$Format = "bv*+ba/b",
    [Parameter(Mandatory=$false)][string]$OutTemplate = "%(title)s [%(id)s].%(ext)s",
    [Parameter(Mandatory=$false)][switch]$AudioOnly,
    [Parameter(Mandatory=$false)][string]$AudioFormat = "m4a",
    [Parameter(Mandatory=$false)][string]$AudioQuality = "192K",
    [Parameter(Mandatory=$false)][switch]$EmbedMeta,
    [Parameter(Mandatory=$false)][switch]$TranscodeWebm = $false,
    [Parameter(Mandatory=$false)][ValidateSet('auto','mp4','webm')]
    [string]$Container = 'auto',
    [Parameter(Mandatory=$false)][switch]$UseSiteFormatFolders,
    [Parameter(Mandatory=$false)][string]$OutBase = ".",
    [Parameter(Mandatory=$false)][switch]$PrintSummary = $true,
    [Parameter(Mandatory=$false)][switch]$ListFormats,
    [Parameter(Mandatory=$false)][string]$Archive,
    [Parameter(Mandatory=$false)][ValidateSet('edge','chrome','chromium','brave','vivaldi','firefox','librewolf','safari','none')]
    [string]$Browser = 'edge',
    [Parameter(Mandatory=$false)][switch]$NoCookies,
    [Parameter(Mandatory=$false)][switch]$Playlist,
    [Parameter(Mandatory=$false)][switch]$Subtitles,
    [Parameter(Mandatory=$false)][string]$SubLangs = "ja.*,en.*",
    [Parameter(Mandatory=$false)][switch]$SponsorBlock,
    [Parameter(Mandatory=$false)][string]$Proxy,
    [Parameter(Mandatory=$false)][int]$Retry = 3,
    [Parameter(Mandatory=$false)][int]$FragmentRetries = 10,
    [Parameter(Mandatory=$false)][switch]$DryRun,
    [Parameter(Mandatory=$false)][string]$Extra = ''
)

$ErrorActionPreference = 'Stop'

function Get-YtDlpExe {
    $local = Join-Path $PSScriptRoot 'yt-dlp.exe'
    if (Test-Path $local) { return $local }
    # Fallback to PATH
    return 'yt-dlp'
}

function Get-HelpText {
    param([string]$Exe)
    try {
        $help = & $Exe --help 2>$null | Out-String
        if (-not $help) { return '' }
        return $help
    } catch { return '' }
}

function Supports-Option {
    param([string]$HelpText, [string]$Option)
    if (-not $HelpText) { return $false }
    $pattern = [Regex]::Escape($Option)
    return [Regex]::IsMatch($HelpText, $pattern)
}

function Get-CookieArgs {
    param([string]$Browser, [switch]$NoCookies)
    if ($NoCookies) { return @() }
    if ($Browser -eq 'none') { return @() }
    return @('--cookies-from-browser', $Browser)
}

function Get-CommonArgs {
    param(
    [string]$Format,[string]$OutTemplate,[string]$Proxy,[int]$Retry,[int]$FragmentRetries,[switch]$Subtitles,[string]$SubLangs,[switch]$SponsorBlock,[string]$Extra,[string]$Archive,[string]$YtHelp,
    [switch]$AudioOnly,[string]$AudioFormat,[string]$AudioQuality,[switch]$EmbedMeta,[switch]$TranscodeWebm,[ValidateSet('auto','mp4','webm')] [string]$Container,[switch]$UseSiteFormatFolders,[string]$OutBase,[switch]$PrintSummary,[switch]$ListFormats
    )
    # Output template auto layout if requested
    $outTmpl = $OutTemplate
    if ($UseSiteFormatFolders -and $OutTemplate -eq "%(title)s [%(id)s].%(ext)s") {
        if ($AudioOnly) {
            $outTmpl = Join-Path $OutBase "Musics/%(extractor_key)s/%(ext)s/%(uploader,NA)s/%(title)s.%(ext)s"
        } else {
            $outTmpl = Join-Path $OutBase "Movies/%(extractor_key)s/%(ext)s/%(title)s [%(id)s].%(ext)s"
        }
    } elseif ($OutBase -and ($OutTemplate -notlike "*:*")) {
        # If a base path is provided and template is relative, prefix it
        $outTmpl = Join-Path $OutBase $OutTemplate
    }

    $args = @('--no-mtime','--no-check-certificates','-N','8','--fragment-retries',"$FragmentRetries",'-R',"$Retry",'-f',$Format,'-o',$outTmpl)
    if ($ListFormats) { $args = @('--list-formats','--yes-playlist') }
    if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--concurrent-fragments')) { $args += @('--concurrent-fragments','4') }
    if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--retry-on-http-error')) { $args += @('--retry-on-http-error','403,429') }
    if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--retry-sleep')) { $args += @('--retry-sleep','2') }
    if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--sleep-requests')) { $args += @('--sleep-requests','1') }
    if ($Archive) { $args += @('--download-archive', $Archive) }
    if ($Proxy) { $args += @('--proxy',$Proxy) }
    if ($Subtitles) { $args += @('--write-auto-subs','--write-subs','--sub-langs',$SubLangs) }
    if ($SponsorBlock) { $args += @('--sponsorblock-remove','sponsor,intro,outro,selfpromo,interaction,preview') }
    if ($AudioOnly) {
        $args += @('-x','--audio-format', $AudioFormat, '--audio-quality', $AudioQuality)
        if ($EmbedMeta) { $args += @('--embed-thumbnail','--embed-metadata','--embed-chapters','--add-metadata') }
    } else {
        # Container preference
        if ($Container -eq 'mp4' -or $TranscodeWebm) {
            # Prefer yt-dlp preset alias if supported
            if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--preset-alias')) {
                $args += @('--preset-alias','mp4')
            } else {
                if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--remux-video')) { $args += @('--remux-video','mp4') }
                if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--merge-output-format')) { $args += @('--merge-output-format','mp4') }
                # Try to prefer compatible codecs for mp4
                if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--format-sort')) { $args += @('-S','vcodec:h264,acodec:aac,lang,quality,res,fps,hdr:12') }
            }
        } elseif ($Container -eq 'webm') {
            if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--merge-output-format')) { $args += @('--merge-output-format','webm') }
            if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--format-sort')) { $args += @('-S','vcodec:vp9,acodec:opus,lang,quality,res,fps') }
        }
    }
    if ($PrintSummary) {
        $summary = 'after_move:[summary] site=%(extractor_key)s id=%(id)s title=%(title).100s res=%(width,NA)sx%(height,NA)s@%(fps,NA)sfps audio=%(acodec,NA)s %(abr,NA)sK %(asr,NA)sHz ch=%(audio_channels,NA)s ext=%(ext)s file=%(filepath)s'
        if ($YtHelp -and (Supports-Option -HelpText $YtHelp -Option '--print')) { $args += @('--print', $summary) }
    }
    if ($Extra) { $args += $Extra.Split(' ') }
    return $args
}

$yt = Get-YtDlpExe
$ytHelp = Get-HelpText -Exe $yt
$cookieArgs = Get-CookieArgs -Browser $Browser -NoCookies:$NoCookies
$common = Get-CommonArgs -Format $Format -OutTemplate $OutTemplate -Proxy $Proxy -Retry $Retry -FragmentRetries $FragmentRetries -Subtitles:$Subtitles -SubLangs $SubLangs -SponsorBlock:$SponsorBlock -Extra $Extra -Archive $Archive -YtHelp $ytHelp -AudioOnly:$AudioOnly -AudioFormat $AudioFormat -AudioQuality $AudioQuality -EmbedMeta:$EmbedMeta -TranscodeWebm:$TranscodeWebm -Container $Container -UseSiteFormatFolders:$UseSiteFormatFolders -OutBase $OutBase -PrintSummary:$PrintSummary -ListFormats:$ListFormats

$targets = @()
if ($Url) { $targets += $Url }
if ($UrlFile) {
    if (-not (Test-Path $UrlFile)) { throw "UrlFile not found: $UrlFile" }
    $targets += Get-Content -LiteralPath $UrlFile | Where-Object { $_ -and (-not $_.StartsWith('#')) }
}
if ($targets.Count -eq 0) { Write-Host "No URL provided."; exit 1 }

$playlistArgs = @()
if ($Playlist) { $playlistArgs += @('--yes-playlist') } else { $playlistArgs += @('--no-playlist') }

$allArgs = @()
$allArgs += $cookieArgs
$allArgs += $common
$allArgs += $playlistArgs
$allArgs += $targets

Write-Host "Running: $yt $($allArgs -join ' ')" -ForegroundColor Cyan
if ($DryRun) { exit 0 }

& $yt @allArgs
$exit = $LASTEXITCODE
exit $exit
