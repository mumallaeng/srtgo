@echo off
setlocal

set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_srtgo.ps1" %*
exit /b %ERRORLEVEL%
