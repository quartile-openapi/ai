@echo off
REM uninstall.bat — Uninstall quartile-dev-toolkit (double-click friendly)
REM
REM Usage:
REM   uninstall.bat

echo.
echo === Quartile Dev Toolkit - Uninstall ===
echo.

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Uninstall failed. Check errors above.
)

pause
