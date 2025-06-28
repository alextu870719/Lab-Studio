# Flutter Windows Build Script
# Run this script in PowerShell on your Windows ARM VM after setup

param(
    [string]$Version = "",
    [switch]$SkipClean = $false
)

# Colors for PowerShell output
$ErrorActionPreference = "Continue"

function Write-Step {
    param($Message)
    Write-Host "=== $Message ===" -ForegroundColor Yellow
}

function Write-Success {
    param($Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param($Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

Write-Host "Lab Studio Windows Build Script" -ForegroundColor Blue
Write-Host "===============================" -ForegroundColor Blue
Write-Host ""

# Get version from pubspec.yaml if not provided
if ([string]::IsNullOrEmpty($Version)) {
    Write-Step "Reading version from pubspec.yaml"
    if (Test-Path "pubspec.yaml") {
        $pubspecContent = Get-Content "pubspec.yaml"
        $versionLine = $pubspecContent | Where-Object { $_ -match "^version:" }
        if ($versionLine) {
            $Version = ($versionLine -split ":")[1].Trim() -replace '\+.*', ''
            Write-Success "Version detected: $Version"
        } else {
            $Version = "1.0.0"
            Write-Info "Version not found, using default: $Version"
        }
    } else {
        Write-Error "pubspec.yaml not found. Are you in the Flutter project directory?"
        exit 1
    }
}

Write-Host "Building Lab Studio v$Version for Windows ARM64" -ForegroundColor Blue
Write-Host ""

# Create releases directory
Write-Step "Preparing build environment"
if (!(Test-Path "releases")) {
    New-Item -ItemType Directory -Path "releases" -Force
    Write-Success "Created releases directory"
}

# Check Flutter installation
Write-Step "Verifying Flutter installation"
try {
    $flutterVersion = flutter --version
    Write-Success "Flutter is installed and working"
    Write-Info $flutterVersion[0]
} catch {
    Write-Error "Flutter not found. Please run the setup script first."
    exit 1
}

# Clean and get dependencies
if (-not $SkipClean) {
    Write-Step "Cleaning previous builds"
    try {
        flutter clean
        Write-Success "Previous builds cleaned"
    } catch {
        Write-Error "Failed to clean: $_"
    }
}

Write-Step "Getting dependencies"
try {
    flutter pub get
    Write-Success "Dependencies updated"
} catch {
    Write-Error "Failed to get dependencies: $_"
    exit 1
}

# Build Windows application
Write-Step "Building Windows application"
Write-Info "This may take several minutes..."
try {
    flutter build windows --release
    Write-Success "Windows application built successfully"
} catch {
    Write-Error "Build failed: $_"
    exit 1
}

# Check if build output exists
$buildPath = "build\windows\x64\runner\Release"
if (!(Test-Path $buildPath)) {
    Write-Error "Build output not found at $buildPath"
    exit 1
}

# Create release archive
Write-Step "Creating release archive"
$outputZip = "releases\Lab-Studio-v$Version-windows-arm64.zip"
$outputExe = "releases\Lab-Studio-v$Version-windows-arm64-installer.exe"

try {
    # Remove existing archive if it exists
    if (Test-Path $outputZip) {
        Remove-Item $outputZip -Force
    }
    
    # Create ZIP archive
    Write-Info "Compressing build output..."
    Compress-Archive -Path "$buildPath\*" -DestinationPath $outputZip -CompressionLevel Optimal
    
    $zipSize = [math]::Round((Get-Item $outputZip).Length / 1MB, 2)
    Write-Success "Created $outputZip ($zipSize MB)"
    
} catch {
    Write-Error "Failed to create archive: $_"
    exit 1
}

# Optional: Create installer using NSIS (if available)
Write-Step "Checking for installer creation tools"
if (Get-Command makensis -ErrorAction SilentlyContinue) {
    Write-Info "NSIS found, creating installer..."
    # You can add NSIS installer script here if needed
    Write-Info "Installer creation skipped (implement if needed)"
} else {
    Write-Info "NSIS not found, skipping installer creation"
    Write-Info "You can install NSIS from: https://nsis.sourceforge.io/Download"
}

# Display build summary
Write-Step "Build Summary"
Write-Host ""
Write-Success "Build completed successfully!"
Write-Info "Version: $Version"
Write-Info "Platform: Windows ARM64"
Write-Info "Build type: Release"
Write-Host ""
Write-Info "Output files:"
if (Test-Path $outputZip) {
    $zipInfo = Get-Item $outputZip
    Write-Host "  • $($zipInfo.Name) ($([math]::Round($zipInfo.Length / 1MB, 2)) MB)" -ForegroundColor Cyan
}
Write-Host ""
Write-Info "Build location: $buildPath"
Write-Host ""

# Show next steps
Write-Step "Next Steps"
Write-Host "1. Test the application:"
Write-Host "   cd $buildPath"
Write-Host "   .\lab_studio.exe"
Write-Host ""
Write-Host "2. Copy the ZIP file to your macOS machine"
Write-Host "3. Upload to GitHub Releases"
Write-Host ""
Write-Info "The ZIP file contains all necessary files to run the app on Windows ARM64 systems."

# Optional: Test run the application
Write-Host ""
$testRun = Read-Host "Do you want to test run the application now? (y/N)"
if ($testRun -eq "y" -or $testRun -eq "Y") {
    Write-Step "Testing application"
    try {
        Write-Info "Starting Lab Studio..."
        Write-Info "Close the application window to continue..."
        & "$buildPath\lab_studio.exe"
        Write-Success "Application test completed"
    } catch {
        Write-Error "Failed to run application: $_"
    }
}

Write-Host ""
Write-Success "Windows ARM64 build process completed!"
