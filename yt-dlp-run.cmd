@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Simple CMD wrapper to run the PowerShell script
set SCRIPT=%~dp0yt-dlp-run.ps1

pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
set EXITCODE=%ERRORLEVEL%
exit /b %EXITCODE%
