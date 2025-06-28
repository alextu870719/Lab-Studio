#!/bin/bash

# Web build script
# Builds Flutter web app and copies to releases

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get version
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

echo -e "${BLUE}Web Build - Version: $VERSION${NC}"

# Create releases directory
mkdir -p releases

# Build Web app
echo -e "${YELLOW}Building Web app...${NC}"
flutter build web --release

# Create zip file
cd build/web/
zip -r "../../releases/Lab-Studio-$VERSION-web.zip" .
cd - > /dev/null

echo -e "${GREEN}✓ Web app built and copied to releases/Lab-Studio-$VERSION-web.zip${NC}"
