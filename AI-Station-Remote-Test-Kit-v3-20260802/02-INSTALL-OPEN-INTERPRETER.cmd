@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install-OpenInterpreter.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (
  echo Open Interpreter installation completed successfully.
) else (
  echo Installation failed. Read README-RU.md and the error above.
)
pause
exit /b %RESULT%

