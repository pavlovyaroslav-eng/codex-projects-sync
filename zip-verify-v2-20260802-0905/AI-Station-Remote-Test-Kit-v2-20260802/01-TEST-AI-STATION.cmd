@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Test-AIStation.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (
  echo Test completed successfully.
) else (
  echo Test failed. Send the TXT report from the reports folder to the administrator.
)
pause
exit /b %RESULT%

