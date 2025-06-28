#!/bin/bash

# Quick build script for development testing
# Builds only Android APK and copies to releases

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get version
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

echo -e "${BLUE}Quick Android Build - Version: $VERSION${NC}"

# Create releases directory
mkdir -p releases

# Build Android APK
echo -e "${YELLOW}Building Android APK...${NC}"
flutter build apk --release

# Copy to releases
cp build/app/outputs/flutter-apk/app-release.apk "releases/Lab-Studio-$VERSION-android.apk"

echo -e "${GREEN}✓ Android APK built and copied to releases/Lab-Studio-$VERSION-android.apk${NC}"
