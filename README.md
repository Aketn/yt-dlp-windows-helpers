# yt-dlp Workspace (Windows)

This repository contains small helpers to use yt-dlp on Windows with VS Code.
It does NOT include downloaded media nor the yt-dlp upstream repo/binary.

## What is included

- `yt-dlp-run.ps1`: PowerShell wrapper around yt-dlp with safer defaults
  - Browser cookies, archive, audio-only, container (mp4/webm) selection
  - Site/format based folder routing (Movies/Musics)
  - Summary print (resolution, audio bitrate/samplerate) after move
  - Help-based option detection for backward-compatible flags
- `yt-dlp-run.cmd`: CMD wrapper to call the PowerShell script
- `ListFormatsCheck.ps1`: Loop to list formats interactively
- `.vscode/tasks.json`: VS Code tasks (quick/advanced, audio-only)
- `.vscode/yt-dlp.code-snippets`: VS Code snippets
- `requirements.txt`: Python deps (yt-dlp via pip)
- `.gitignore`: Excludes media, temp, binaries, and local upstream clone

## Prerequisites

- Windows, PowerShell 7+
- yt-dlp (PATH or `yt-dlp.exe` in repo root)
- ffmpeg/ffprobe on PATH

## Quick start

1. Open this folder in VS Code
2. Run Task: "yt-dlp: Download URL (quick)" and input URL and browser
3. Outputs are routed into `Movies/` or `Musics/` automatically

### About "quick" tasks (speed-first)

- Quick tasks prioritize speed and simplicity. They download a single best progressive stream without merging.
- Therefore, they do NOT guarantee a specific resolution or container/codec.
  - If the site only provides progressive MP4 for the chosen quality, you'll get MP4 even if `-Container` is set to webm.
  - HLS (m3u8) is deprioritized to avoid slowness, but may still be used if no alternative exists.
- Subtitles (ja,en) are still saved as sidecar SRT files.

If you need consistent quality or format, use one of the following instead:

- High quality with audio >=192k (single audio):
  - Task: "yt-dlp: Download URL (prefer >=192k audio)"
- Dual-audio (ja+en) and robust merging with metadata (recommended):
  - Task: "yt-dlp: Download URL (ja+en audio, mkv multi)"
  - Uses MKV container and merges multiple audio tracks reliably; avoids m3u8 where possible.

## Subtitles (default behavior)

- Quick tasks automatically fetch English/Japanese subtitles (langs: `ja,en`).
- Subtitles are converted to SRT and saved under `Subtitles/<Title [ID]>/*.srt` per video.
- If both languages exist, both are saved as separate files in that folder, e.g.:
  - `Subtitles/Title [VIDEO_ID]/ja.srt`
  - `Subtitles/Title [VIDEO_ID]/en.srt`
- Videos are not modified; subtitles are kept as sidecar files.
- If you want to embed subtitles into a single file later, see hints below.

### Embed subtitles later (optional)

MKV (no re-encode):

```powershell
ffmpeg -i "video.mp4" -i "Subtitles/Title [VIDEO_ID]/ja.srt" -c copy -c:s srt "video.withsub.mkv"
```

MP4 (mov_text):

```powershell
ffmpeg -i "video.mp4" -i "Subtitles/Title [VIDEO_ID]/ja.srt" -c copy -c:s mov_text "video.withsub.mp4"
```

## Audio-only preset

Use the task: "yt-dlp: Audio-only (m4a 192K, by site/uploader)"

## Format listing

Run the task: "yt-dlp: List formats (loop)" or execute `./ListFormatsCheck.ps1`

## Notes

- For older yt-dlp versions, unsupported flags are auto-suppressed
- To update yt-dlp binary: `yt-dlp.exe -U`

## License

This helper configuration is MIT-licensed. yt-dlp is licensed separately (see upstream).
