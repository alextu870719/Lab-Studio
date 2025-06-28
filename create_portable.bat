@echo off
echo Creating self-extracting executable...

echo.
echo Step 1: Creating temporary directory structure...
if exist "temp_package" rmdir /s /q "temp_package"
mkdir "temp_package"

echo Step 2: Copying all required files...
xcopy "build\windows\x64\runner\Release\*" "temp_package\" /E /I /H /Y

echo Step 3: Creating launcher script...
echo @echo off > "temp_package\launch.bat"
echo cd /d "%%~dp0" >> "temp_package\launch.bat"
echo start "" "lab_studio.exe" >> "temp_package\launch.bat"

echo Step 4: Creating README...
echo Lab Studio - Portable Windows Application > "temp_package\README.txt"
echo. >> "temp_package\README.txt"
echo This is a portable version of Lab Studio. >> "temp_package\README.txt"
echo Double-click launch.bat to run the application. >> "temp_package\README.txt"
echo. >> "temp_package\README.txt"
echo All files are self-contained in this directory. >> "temp_package\README.txt"

echo Step 5: Creating PowerShell self-extractor...
powershell -Command "& {
    $source = 'temp_package'
    $destination = 'Lab-Studio-Portable-v1.0.1.exe'
    
    # Create a self-extracting PowerShell script
    $script = @'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$tempDir = Join-Path $env:TEMP 'LabStudio_' + [System.Guid]::NewGuid().ToString()
[System.IO.Compression.ZipFile]::ExtractToDirectory($PSCommandPath, $tempDir)
Set-Location $tempDir
Start-Process 'launch.bat' -Wait
Remove-Item $tempDir -Recurse -Force
'@
    
    # Compress the temp_package folder
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory('temp_package', 'temp.zip')
    
    # Create the self-extracting exe (this is a simplified approach)
    # For a real self-extracting exe, you'd need additional tools
    Rename-Item 'temp.zip' 'Lab-Studio-Portable-v1.0.1.zip'
    Remove-Item 'temp.zip' -ErrorAction SilentlyContinue
}"

echo.
echo Cleaning up temporary files...
rmdir /s /q "temp_package"

echo.
echo Portable application created: Lab-Studio-Portable-v1.0.1.zip
echo.
echo To create a true self-extracting exe, you would need tools like:
echo - 7-Zip (7z a -sfx Lab-Studio.exe files)
echo - WinRAR
echo - NSIS (Nullsoft Scriptable Install System)
echo.
pause
