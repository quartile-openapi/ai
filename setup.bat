@echo off
REM setup.bat — Bootstrap quartile-dev-toolkit (double-click friendly)
REM
REM Usage:
REM   setup.bat                          Uses UV_EXTRA_INDEX_URL env var
REM   setup.bat "<FEED_URL>"             Passes URL to setup.ps1

echo.
echo === Quartile Dev Toolkit - Setup ===
echo.

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found.
    pause
    exit /b 1
)

if "%~1"=="" (
    powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
) else (
    powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -FeedUrl "%~1"
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Setup failed. Check errors above.
)

pause
