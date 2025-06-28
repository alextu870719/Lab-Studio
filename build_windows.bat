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
echo Build completed!
echo The Windows application should be in: build\windows\x64\runner\Release\
echo.
pause
