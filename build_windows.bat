@echo off
echo Starting Windows build process...
echo.

echo Setting up Flutter environment...
set FLUTTER_PATH=C:\Users\chi-kuantu\Downloads\flutter\bin\flutter.bat

echo Enabling Windows desktop support...
%FLUTTER_PATH% config --enable-windows-desktop

echo Getting dependencies...
%FLUTTER_PATH% pub get

echo Building Windows application...
%FLUTTER_PATH% build windows --release

echo.
echo Creating self-contained executable...
echo Installing dependencies for packaging...
%FLUTTER_PATH% pub global activate flutter_distributor

echo Creating Windows installer with Inno Setup...
if not exist "installer_output" mkdir "installer_output"

echo Compiling installer with Inno Setup...
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "lab_studio_installer.iss"

if exist "installer_output\Lab-Studio-v1.0.1-Windows-Installer.exe" (
    echo.
    echo ✅ Installer created successfully!
    echo Installer location: installer_output\Lab-Studio-v1.0.1-Windows-Installer.exe
) else (
    echo.
    echo ❌ Installer creation failed. Please check if Inno Setup is installed correctly.
    echo Expected path: C:\Program Files (x86)\Inno Setup 6\ISCC.exe
)

echo.
echo Build completed!
echo Regular build files are in: build\windows\x64\runner\Release\
echo Windows Installer is in: installer_output\
echo.
pause
