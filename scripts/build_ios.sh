#!/bin/bash

# iOS build script for macOS
# Builds iOS IPA and copies to releases

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: iOS builds can only be performed on macOS${NC}"
    exit 1
fi

# Get version
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

echo -e "${BLUE}iOS Build - Version: $VERSION${NC}"

# Create releases directory
mkdir -p releases

# Build iOS IPA
echo -e "${YELLOW}Building iOS IPA...${NC}"
flutter build ipa --release

# Find and copy IPA file
IPA_FILE=$(find build/ios/ipa -name "*.ipa" | head -1)
if [ -n "$IPA_FILE" ]; then
    cp "$IPA_FILE" "releases/Lab-Studio-$VERSION-ios.ipa"
    echo -e "${GREEN}✓ iOS IPA built and copied to releases/Lab-Studio-$VERSION-ios.ipa${NC}"
else
    echo -e "${RED}✗ iOS IPA file not found${NC}"
    exit 1
fi
