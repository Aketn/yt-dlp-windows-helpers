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

## Audio-only preset

Use the task: "yt-dlp: Audio-only (m4a 192K, by site/uploader)"

## Format listing

Run the task: "yt-dlp: List formats (loop)" or execute `./ListFormatsCheck.ps1`

## Notes

- For older yt-dlp versions, unsupported flags are auto-suppressed
- To update yt-dlp binary: `yt-dlp.exe -U`

## License

This helper configuration is MIT-licensed. yt-dlp is licensed separately (see upstream).
