# Lab Studio - Build Automation
# Usage: make [target]

.PHONY: all android ios macos web clean help install-deps release github-setup docker-windows

# Default target
all: clean
	@echo "Building Lab Studio for all platforms..."
	@./scripts/build_and_release.sh

# Build and upload to GitHub Releases
release: all
	@echo "Uploading to GitHub Releases..."
	@./scripts/github_release.sh

# Build Windows app using Docker
docker-windows:
	@echo "Building Windows app using Docker..."
	@./scripts/build_windows_docker.sh

# Quick Android build
android:
	@echo "Building Android APK..."
	@./scripts/quick_build_android.sh

# iOS build (macOS only)
ios:
	@echo "Building iOS IPA..."
	@./scripts/build_ios.sh

# macOS build (macOS only)
macos:
	@echo "Building macOS app..."
	@./scripts/build_macos.sh

# Web build
web:
	@echo "Building Web app..."
	@./scripts/build_web.sh

# Clean build files
clean:
	@echo "Cleaning build files..."
	@flutter clean
	@flutter pub get

# Install dependencies for better macOS packaging
install-deps:
	@echo "Installing create-dmg for better macOS packaging..."
	@brew install create-dmg

# Setup GitHub CLI and authentication
github-setup:
	@echo "Setting up GitHub CLI..."
	@if ! command -v gh &> /dev/null; then \
		echo "Installing GitHub CLI..."; \
		brew install gh; \
	fi
	@echo "Authenticating with GitHub..."
	@gh auth login

# Upload existing release files to GitHub
github-upload:
	@echo "Uploading to GitHub Releases..."
	@./scripts/github_release.sh

# Setup Windows VM for building
windows-vm-setup:
	@echo "Setting up Windows VM file transfer..."
	@./scripts/windows_vm_transfer.sh

# Show available commands
help:
	@echo "Available commands:"
	@echo "  make all           - Build for all platforms"
	@echo "  make release       - Build and upload to GitHub Releases"
	@echo "  make android       - Build Android APK only"
	@echo "  make ios           - Build iOS IPA only (macOS only)"
	@echo "  make macos         - Build macOS app only (macOS only)"
	@echo "  make web           - Build Web app only"
	@echo "  make docker-windows - Build Windows app using Docker"
	@echo "  make clean         - Clean build files and get dependencies"
	@echo "  make install-deps  - Install additional tools for better packaging"
	@echo "  make github-setup  - Setup GitHub CLI and authentication"
	@echo "  make github-upload - Upload existing files to GitHub Releases"
	@echo "  make windows-vm-setup - Setup Windows VM for building"
	@echo "  make help          - Show this help message"
