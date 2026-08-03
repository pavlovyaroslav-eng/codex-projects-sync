@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Verify-Checksums.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
pause
exit /b %RESULT%

