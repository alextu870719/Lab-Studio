@echo off
echo Flutter Windows ARM Build Launcher
echo ==================================
echo.

echo Starting Flutter build with bypass execution policy...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0windows_arm_build.ps1" %*

echo.
echo Build script completed!
echo.
pause
