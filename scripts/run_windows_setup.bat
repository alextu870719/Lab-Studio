@echo off
echo Flutter Windows ARM Setup Launcher
echo ===================================
echo.

echo Checking PowerShell execution policy...
powershell -Command "Get-ExecutionPolicy -Scope CurrentUser"

echo.
echo Starting Flutter setup with bypass execution policy...
echo This will automatically handle execution policy issues.
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0windows_arm_setup.ps1"

echo.
echo Setup script completed!
echo.
pause
