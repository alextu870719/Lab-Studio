#!/bin/bash

# Lab Studio - Build and Release Script
# This script builds the Flutter app for all platforms and copies outputs to releases folder

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')
BUILD_NUMBER=$(grep "version:" pubspec.yaml | sed 's/.*+//g')

echo -e "${BLUE}Lab Studio Build and Release Script${NC}"
echo -e "${BLUE}Version: $VERSION+$BUILD_NUMBER${NC}"
echo ""

# Create releases directory if it doesn't exist
mkdir -p releases

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

# Clean previous builds
print_step "Cleaning previous builds"
flutter clean
flutter pub get
print_success "Cleaned and updated dependencies"

# Build for Android (APK)
print_step "Building Android APK"
if flutter build apk --release; then
    cp build/app/outputs/flutter-apk/app-release.apk "releases/Lab-Studio-$VERSION-android.apk"
    print_success "Android APK built and copied to releases"
else
    print_error "Android APK build failed"
fi

# Build for Android (App Bundle)
print_step "Building Android App Bundle"
if flutter build appbundle --release; then
    cp build/app/outputs/bundle/release/app-release.aab "releases/Lab-Studio-$VERSION-android.aab"
    print_success "Android App Bundle built and copied to releases"
else
    print_error "Android App Bundle build failed"
fi

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_step "Building iOS IPA"
    if flutter build ipa --release; then
        # Find the IPA file in the build directory
        IPA_FILE=$(find build/ios/ipa -name "*.ipa" | head -1)
        if [ -n "$IPA_FILE" ]; then
            cp "$IPA_FILE" "releases/Lab-Studio-$VERSION-ios.ipa"
            print_success "iOS IPA built and copied to releases"
        else
            print_error "iOS IPA file not found"
        fi
    else
        print_error "iOS IPA build failed"
    fi
fi

# Build for macOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_step "Building macOS app"
    if flutter build macos --release; then
        # Create DMG from the built app
        APP_NAME="Lab Studio"
        DMG_NAME="Lab-Studio-$VERSION-macos.dmg"
        
        # Remove existing DMG if it exists
        rm -f "releases/$DMG_NAME"
        
        # Create DMG
        if command -v create-dmg &> /dev/null; then
            create-dmg \
                --volname "$APP_NAME" \
                --window-pos 200 120 \
                --window-size 600 300 \
                --icon-size 100 \
                --icon "$APP_NAME.app" 175 120 \
                --hide-extension "$APP_NAME.app" \
                --app-drop-link 425 120 \
                "releases/$DMG_NAME" \
                "build/macos/Build/Products/Release/$APP_NAME.app"
            print_success "macOS DMG created and copied to releases"
        else
            # Fallback: create a zip file
            cd build/macos/Build/Products/Release/
            zip -r "../../../../../releases/Lab-Studio-$VERSION-macos.zip" "$APP_NAME.app"
            cd - > /dev/null
            print_success "macOS app zipped and copied to releases"
        fi
    else
        print_error "macOS build failed"
    fi
fi

# Build for Linux (if on Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_step "Building Linux app"
    if flutter build linux --release; then
        cd build/linux/x64/release/bundle/
        tar -czf "../../../../../releases/Lab-Studio-$VERSION-linux.tar.gz" .
        cd - > /dev/null
        print_success "Linux app built and copied to releases"
    else
        print_error "Linux build failed"
    fi
fi

# Build for Web
print_step "Building Web app"
if flutter build web --release; then
    cd build/web/
    zip -r "../../releases/Lab-Studio-$VERSION-web.zip" .
    cd - > /dev/null
    print_success "Web app built and copied to releases"
else
    print_error "Web build failed"
fi

# Build for Windows (if on Windows or with cross-compilation)
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    print_step "Building Windows app"
    if flutter build windows --release; then
        cd build/windows/x64/runner/Release/
        zip -r "../../../../../releases/Lab-Studio-$VERSION-windows.zip" .
        cd - > /dev/null
        print_success "Windows app built and copied to releases"
    else
        print_error "Windows build failed"
    fi
else
    # On macOS/Linux, trigger GitHub Actions to build Windows app
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        print_step "Triggering Windows build via GitHub Actions"
        echo -e "${YELLOW}由於目前在 macOS 上，將使用 GitHub Actions 建置 Windows 應用程式${NC}"
        
        if gh workflow run build-windows.yml -f version="$VERSION"; then
            print_success "Windows 建置工作流程已觸發"
            echo -e "${BLUE}請前往 GitHub Actions 查看建置進度: https://github.com/alextu870719/Lab-Studio/actions${NC}"
            echo -e "${YELLOW}建置完成後，Windows ZIP 檔案將可在 Artifacts 中下載${NC}"
        else
            print_error "無法觸發 GitHub Actions 工作流程"
            echo -e "${YELLOW}您可以手動前往 GitHub 觸發工作流程，或使用虛擬機器建置${NC}"
        fi
    else
        print_step "Windows build options on macOS"
        echo -e "${YELLOW}在 macOS 上建置 Windows 應用程式的選項：${NC}"
        echo "1. 使用 GitHub Actions (自動) - 需要推送到 GitHub"
        echo "2. 使用虛擬機器 (Parallels/VirtualBox/UTM)"
        echo "3. 使用雲端建置服務"
        echo ""
        echo -e "${BLUE}執行以下指令獲取詳細設定指南：${NC}"
        echo "./scripts/setup_windows_vm.sh"
    fi
fi

# List all files in releases directory
print_step "Release files created"
ls -la releases/Lab-Studio-$VERSION*

# Upload to GitHub Releases
if command -v gh &> /dev/null; then
    print_step "Uploading to GitHub Releases"
    
    # Check if user is authenticated with GitHub CLI
    if gh auth status &> /dev/null; then
        # Create release tag
        RELEASE_TAG="v$VERSION"
        RELEASE_TITLE="Lab Studio v$VERSION"
        RELEASE_NOTES="releases/RELEASE_NOTES_v$VERSION.md"
        
        # Create release notes if it doesn't exist
        if [ ! -f "$RELEASE_NOTES" ]; then
            cat > "$RELEASE_NOTES" << EOF
# Lab Studio v$VERSION

## 新功能與改進
- 版本 $VERSION 的更新內容

## 下載
- **Android APK**: 適用於 Android 裝置
- **Android AAB**: 用於 Google Play Store 上傳
- **iOS IPA**: 適用於 iOS 裝置 (需要 iOS 開發者帳號)
- **macOS DMG/ZIP**: 適用於 macOS 系統
- **Web ZIP**: 可部署至網頁伺服器
- **Linux TAR.GZ**: 適用於 Linux 系統

## 安裝說明
請參考 README.md 和 BUILD_GUIDE.md 獲取詳細安裝指南。

---
自動生成於 $(date)
EOF
            print_success "Created release notes: $RELEASE_NOTES"
        fi
        
        # Check if release already exists
        if gh release view "$RELEASE_TAG" &> /dev/null; then
            echo -e "${YELLOW}Release $RELEASE_TAG already exists. Updating...${NC}"
            
            # Upload all release files
            for file in releases/Lab-Studio-$VERSION*; do
                if [ -f "$file" ]; then
                    echo "Uploading $(basename "$file")..."
                    gh release upload "$RELEASE_TAG" "$file" --clobber
                fi
            done
        else
            echo -e "${YELLOW}Creating new release $RELEASE_TAG...${NC}"
            
            # Create new release
            gh release create "$RELEASE_TAG" \
                --title "$RELEASE_TITLE" \
                --notes-file "$RELEASE_NOTES" \
                --draft \
                releases/Lab-Studio-$VERSION*
        fi
        
        print_success "Files uploaded to GitHub Releases: https://github.com/alextu870719/Lab-Studio/releases"
        echo -e "${BLUE}Release URL: https://github.com/alextu870719/Lab-Studio/releases/tag/$RELEASE_TAG${NC}"
        
    else
        print_error "GitHub CLI not authenticated. Please run: gh auth login"
        echo -e "${YELLOW}Files are saved locally in releases/ directory${NC}"
    fi
else
    print_error "GitHub CLI not installed. Please install it: brew install gh"
    echo -e "${YELLOW}Files are saved locally in releases/ directory${NC}"
fi

echo ""
echo -e "${GREEN}Build and release process completed!${NC}"
echo -e "${BLUE}Files are available in the releases/ directory${NC}"
