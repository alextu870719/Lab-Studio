#!/bin/bash

# Docker Windows Build Script for Lab Studio
# This script builds Windows Flutter app using Docker cross-compilation

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

echo -e "${BLUE}Docker Windows Build for Lab Studio${NC}"
echo -e "${BLUE}Version: $VERSION${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "${YELLOW}=== $1 ===${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

print_step "Preparing Docker build environment"

# Create releases directory
mkdir -p releases
# Build the Docker image
IMAGE_NAME="lab-studio-windows-builder"

print_step "Building Docker image for Windows cross-compilation"
if docker build -f Dockerfile.windows-cross -t $IMAGE_NAME .; then
    print_success "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

print_step "Running Windows build in Docker container"

# Run the build in Docker container
if docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace \
    $IMAGE_NAME; then
    
    print_success "Docker build completed"
    
    # Check if the Windows zip file was created
    WINDOWS_ZIP="releases/Lab-Studio-$VERSION-windows.zip"
    if [ -f "$WINDOWS_ZIP" ]; then
        print_success "Windows app created: $WINDOWS_ZIP"
        
        # Show file info
        echo ""
        echo -e "${BLUE}Build Results:${NC}"
        ls -lh "$WINDOWS_ZIP"
        echo ""
        
        # Extract and show contents
        echo -e "${BLUE}Package Contents:${NC}"
        unzip -l "$WINDOWS_ZIP" | head -10
        
        echo ""
        print_success "Windows build process completed successfully!"
        echo -e "${BLUE}The Windows app is ready at: $WINDOWS_ZIP${NC}"
        
    else
        print_error "Windows zip file was not created"
        echo "Build may have failed inside the container"
        
        # Show alternative options
        echo ""
        echo -e "${YELLOW}Alternative solutions:${NC}"
        echo "1. Use GitHub Actions: ./scripts/build_windows_github.sh"
        echo "2. Use a Windows VM: ./scripts/setup_windows_vm.sh"
        exit 1
    fi
    
else
    print_error "Docker build failed"
    echo ""
    echo -e "${YELLOW}Flutter Windows cross-compilation has limitations.${NC}"
    echo -e "${YELLOW}Consider using these alternatives:${NC}"
    echo "1. GitHub Actions (recommended): ./scripts/build_windows_github.sh"
    echo "2. Windows VM setup: ./scripts/setup_windows_vm.sh"
    exit 1
fi

# Optional: Clean up the Docker image to save space
echo ""
read -p "Do you want to remove the Docker image to save space? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi $IMAGE_NAME
    print_success "Docker image removed"
fi

echo ""
echo -e "${GREEN}All done! 🎉${NC}"
echo -e "${BLUE}Your Windows app is ready in the releases folder${NC}"
