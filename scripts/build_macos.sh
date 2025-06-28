#!/bin/bash

# macOS build script
# Builds macOS app and creates DMG, copies to releases

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: macOS builds can only be performed on macOS${NC}"
    exit 1
fi

# Get version
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

echo -e "${BLUE}macOS Build - Version: $VERSION${NC}"

# Create releases directory
mkdir -p releases

# Build macOS app
echo -e "${YELLOW}Building macOS app...${NC}"
flutter build macos --release

# Create DMG or ZIP
APP_NAME="lab_studio"
DMG_NAME="Lab-Studio-$VERSION-macos.dmg"

# Remove existing DMG if it exists
rm -f "releases/$DMG_NAME"

# Check if create-dmg is available
if command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Creating DMG...${NC}"
    create-dmg \
        --volname "Lab Studio" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 175 120 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 425 120 \
        "releases/$DMG_NAME" \
        "build/macos/Build/Products/Release/$APP_NAME.app"
    echo -e "${GREEN}✓ macOS DMG created: releases/$DMG_NAME${NC}"
else
    echo -e "${YELLOW}create-dmg not found, creating ZIP instead...${NC}"
    cd build/macos/Build/Products/Release/
    zip -r "../../../../../releases/Lab-Studio-$VERSION-macos.zip" "$APP_NAME.app"
    cd - > /dev/null
    echo -e "${GREEN}✓ macOS app zipped: releases/Lab-Studio-$VERSION-macos.zip${NC}"
    echo -e "${YELLOW}Install create-dmg for better packaging: brew install create-dmg${NC}"
fi
