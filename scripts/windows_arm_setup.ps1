# Flutter Windows ARM Setup Script
# Run this script in PowerShell on your Windows ARM VM

# Check and set execution policy if needed
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
    Write-Host "Current execution policy is restrictive: $currentPolicy" -ForegroundColor Yellow
    Write-Host "Setting execution policy to RemoteSigned for current user..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "✓ Execution policy updated successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to set execution policy. Please run as administrator or set manually." -ForegroundColor Red
        Write-Host "Run this command as administrator: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine" -ForegroundColor Yellow
        Read-Host "Press Enter to continue anyway..."
    }
}

# Colors for PowerShell output
$ErrorActionPreference = "Stop"

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

Write-Host "Flutter Windows ARM Setup Script" -ForegroundColor Blue
Write-Host "=================================" -ForegroundColor Blue
Write-Host ""

# Check if running on ARM64
Write-Step "Checking Windows ARM64 environment"
$arch = (Get-WmiObject -Class Win32_Processor).Architecture
if ($arch -eq 12) {
    Write-Success "Detected Windows ARM64 architecture"
} else {
    Write-Info "Architecture: $arch (Expected 12 for ARM64)"
}

# Create development directory
Write-Step "Creating development directories"
$DevDir = "C:\dev"
$FlutterDir = "$DevDir\flutter"
if (!(Test-Path $DevDir)) {
    New-Item -ItemType Directory -Path $DevDir -Force
    Write-Success "Created $DevDir"
}

# Download and install Git for Windows
Write-Step "Installing Git for Windows"
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Info "Downloading Git for Windows..."
    $GitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    $GitInstaller = "$env:TEMP\Git-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $GitUrl -OutFile $GitInstaller
        Write-Info "Installing Git..."
        Start-Process -FilePath $GitInstaller -Args "/SILENT" -Wait
        
        # Add Git to PATH for current session
        $env:PATH += ";C:\Program Files\Git\bin"
        Write-Success "Git installed successfully"
    } catch {
        Write-Error "Failed to install Git: $_"
        Write-Info "Please download and install Git manually from: https://git-scm.com/download/win"
    }
} else {
    Write-Success "Git is already installed"
}

# Download and install Flutter SDK
Write-Step "Installing Flutter SDK"
if (!(Test-Path $FlutterDir)) {
    Write-Info "Downloading Flutter SDK for Windows..."
    $FlutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.32.4-stable.zip"
    $FlutterZip = "$env:TEMP\flutter_windows.zip"
    
    try {
        Write-Info "This may take a few minutes..."
        Invoke-WebRequest -Uri $FlutterUrl -OutFile $FlutterZip
        
        Write-Info "Extracting Flutter SDK..."
        Expand-Archive -Path $FlutterZip -DestinationPath $DevDir -Force
        Write-Success "Flutter SDK extracted to $FlutterDir"
        
        # Clean up
        Remove-Item $FlutterZip -Force
    } catch {
        Write-Error "Failed to download Flutter: $_"
        Write-Info "Please download Flutter manually from: https://docs.flutter.dev/get-started/install/windows"
        exit 1
    }
} else {
    Write-Success "Flutter SDK already exists"
}

# Add Flutter to PATH
Write-Step "Configuring Flutter PATH"
$FlutterBin = "$FlutterDir\bin"
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($CurrentPath -notlike "*$FlutterBin*") {
    $NewPath = "$CurrentPath;$FlutterBin"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    $env:PATH += ";$FlutterBin"
    Write-Success "Added Flutter to PATH"
} else {
    Write-Success "Flutter already in PATH"
}

# Install Visual Studio Build Tools
Write-Step "Installing Visual Studio Build Tools"
$VSInstaller = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe"
if (!(Test-Path $VSInstaller)) {
    Write-Info "Downloading Visual Studio Build Tools..."
    $VSUrl = "https://aka.ms/vs/17/release/vs_buildtools.exe"
    $VSBuildTools = "$env:TEMP\vs_buildtools.exe"
    
    try {
        Invoke-WebRequest -Uri $VSUrl -OutFile $VSBuildTools
        Write-Info "Installing Visual Studio Build Tools (this will take some time)..."
        Start-Process -FilePath $VSBuildTools -Args "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" -Wait
        Write-Success "Visual Studio Build Tools installed"
    } catch {
        Write-Error "Failed to install Visual Studio Build Tools: $_"
        Write-Info "Please install manually from: https://visualstudio.microsoft.com/downloads/"
    }
} else {
    Write-Success "Visual Studio Build Tools already installed"
}

# Run Flutter doctor
Write-Step "Running Flutter doctor"
try {
    & "$FlutterBin\flutter.bat" doctor
    Write-Success "Flutter doctor completed"
} catch {
    Write-Error "Flutter doctor failed: $_"
}

# Enable Windows desktop development
Write-Step "Enabling Windows desktop development"
try {
    & "$FlutterBin\flutter.bat" config --enable-windows-desktop
    Write-Success "Windows desktop development enabled"
} catch {
    Write-Error "Failed to enable Windows desktop: $_"
}

Write-Host ""
Write-Host "Flutter Setup Complete!" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host ""
Write-Info "Next steps:"
Write-Host "1. Restart your PowerShell session or reboot Windows"
Write-Host "2. Clone your Flutter project"
Write-Host "3. Run 'flutter doctor' to verify installation"
Write-Host "4. Use the build script to compile your app"
Write-Host ""
Write-Info "To clone your project:"
Write-Host "git clone https://github.com/alextu870719/Lab-Studio.git"
Write-Host "cd Lab-Studio"
Write-Host ""
Write-Info "To build your Windows app:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter build windows --release"
