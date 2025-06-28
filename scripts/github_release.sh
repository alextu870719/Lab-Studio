#!/bin/bash

# GitHub Release Upload Script
# This script uploads built files to GitHub Releases

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')
BUILD_NUMBER=$(grep "version:" pubspec.yaml | sed 's/.*+//g')

echo -e "${BLUE}GitHub Release Upload Script${NC}"
echo -e "${BLUE}Version: $VERSION+$BUILD_NUMBER${NC}"
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

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI not installed"
    echo "Please install GitHub CLI:"
    echo "  macOS: brew install gh"
    echo "  Other: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI not authenticated"
    echo "Please authenticate with GitHub:"
    echo "  gh auth login"
    exit 1
fi

# Check if release files exist
RELEASE_FILES=(releases/Lab-Studio-$VERSION*)
if [ ! -f "${RELEASE_FILES[0]}" ]; then
    print_error "No release files found for version $VERSION"
    echo "Please run the build script first:"
    echo "  ./scripts/build_and_release.sh"
    echo "  or: make all"
    exit 1
fi

print_step "Preparing GitHub Release"

RELEASE_TAG="v$VERSION"
RELEASE_TITLE="Lab Studio v$VERSION"
RELEASE_NOTES_FILE="releases/RELEASE_NOTES_v$VERSION.md"

# Create release notes if it doesn't exist
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    print_step "Creating release notes"
    cat > "$RELEASE_NOTES_FILE" << EOF
# Lab Studio v$VERSION

## 🚀 新功能與改進

### 版本 $VERSION 更新內容
- [請在這裡描述這個版本的新功能和改進]
- [例如：修復了 PCR 計算的精度問題]
- [例如：改善了使用者介面的響應性]

## 📱 支援平台

此版本支援以下平台：
- **Android** (API 21+)
- **iOS** (iOS 12.0+)
- **macOS** (macOS 10.14+)
- **Web** (現代瀏覽器)
- **Linux** (x64)
- **Windows** (x64)

## 📦 下載檔案說明

| 檔案類型 | 用途 | 安裝方式 |
|---------|------|----------|
| **android.apk** | Android 裝置直接安裝 | 下載後直接安裝 |
| **android.aab** | Google Play Store 上傳 | 開發者用於商店上傳 |
| **ios.ipa** | iOS 裝置安裝 | 需要開發者帳號或企業簽名 |
| **macos.dmg** | macOS 安裝包 | 雙擊開啟並拖拽到應用程式資料夾 |
| **web.zip** | 網頁版本 | 解壓縮後部署到網頁伺服器 |
| **linux.tar.gz** | Linux 版本 | 解壓縮後執行 |

## 🛠️ 安裝說明

### Android
1. 下載 \`Lab-Studio-$VERSION-android.apk\`
2. 在裝置上啟用「未知來源」安裝權限
3. 點擊 APK 檔案進行安裝

### iOS
1. 下載 \`Lab-Studio-$VERSION-ios.ipa\`
2. 使用 Xcode 或第三方工具安裝到裝置
3. 注意：需要有效的開發者憑證

### macOS
1. 下載 \`Lab-Studio-$VERSION-macos.dmg\`
2. 雙擊開啟 DMG 檔案
3. 將應用程式拖拽到「應用程式」資料夾

### Web
1. 下載 \`Lab-Studio-$VERSION-web.zip\`
2. 解壓縮到網頁伺服器目錄
3. 透過瀏覽器存取 \`index.html\`

## 🐛 已知問題

- [如有已知問題請在此列出]

## 📋 系統需求

- **Android**: Android 5.0 (API 21) 或更高版本
- **iOS**: iOS 12.0 或更高版本
- **macOS**: macOS 10.14 或更高版本
- **Web**: Chrome 88+, Firefox 85+, Safari 14+, Edge 88+

## 🔗 相關連結

- [專案首頁](https://github.com/alextu870719/Lab-Studio)
- [使用說明](https://github.com/alextu870719/Lab-Studio/blob/main/README.md)
- [建置指南](https://github.com/alextu870719/Lab-Studio/blob/main/BUILD_GUIDE.md)
- [問題回報](https://github.com/alextu870719/Lab-Studio/issues)

---
📅 發布日期: $(date +"%Y-%m-%d")  
🔧 建置編號: $BUILD_NUMBER  
📦 自動建置與發布
EOF
    print_success "Created release notes: $RELEASE_NOTES_FILE"
    echo -e "${YELLOW}請編輯 $RELEASE_NOTES_FILE 來自訂發布說明${NC}"
fi

# Check if release already exists
if gh release view "$RELEASE_TAG" &> /dev/null; then
    print_step "Updating existing release $RELEASE_TAG"
    
    # Ask user if they want to update the existing release
    echo -e "${YELLOW}Release $RELEASE_TAG already exists.${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作取消"
        exit 0
    fi
    
    # Upload all release files
    for file in releases/Lab-Studio-$VERSION*; do
        if [ -f "$file" ] && [[ "$file" != *.md ]]; then
            filename=$(basename "$file")
            echo "Uploading $filename..."
            if gh release upload "$RELEASE_TAG" "$file" --clobber; then
                print_success "Uploaded $filename"
            else
                print_error "Failed to upload $filename"
            fi
        fi
    done
    
else
    print_step "Creating new release $RELEASE_TAG"
    
    # Ask user about release type
    echo -e "${YELLOW}Release options:${NC}"
    echo "1. Draft release (可以先預覽再發布)"
    echo "2. Pre-release (標記為預發布版本)"
    echo "3. Public release (立即公開發布)"
    read -p "選擇發布類型 (1-3, 預設為 1): " choice
    
    RELEASE_OPTIONS=""
    case $choice in
        2)
            RELEASE_OPTIONS="--prerelease"
            ;;
        3)
            # Public release, no additional options needed
            ;;
        *)
            RELEASE_OPTIONS="--draft"
            ;;
    esac
    
    # Create new release with all files
    RELEASE_FILES_TO_UPLOAD=()
    for file in releases/Lab-Studio-$VERSION*; do
        if [ -f "$file" ] && [[ "$file" != *.md ]]; then
            RELEASE_FILES_TO_UPLOAD+=("$file")
        fi
    done
    
    if [ ${#RELEASE_FILES_TO_UPLOAD[@]} -eq 0 ]; then
        print_error "No release files found to upload"
        exit 1
    fi
    
    echo "Creating release with ${#RELEASE_FILES_TO_UPLOAD[@]} files..."
    
    if gh release create "$RELEASE_TAG" \
        --title "$RELEASE_TITLE" \
        --notes-file "$RELEASE_NOTES_FILE" \
        $RELEASE_OPTIONS \
        "${RELEASE_FILES_TO_UPLOAD[@]}"; then
        
        print_success "Release created successfully!"
    else
        print_error "Failed to create release"
        exit 1
    fi
fi

# Show release information
print_step "Release Information"
gh release view "$RELEASE_TAG"

echo ""
print_success "GitHub Release process completed!"
echo -e "${BLUE}Release URL: https://github.com/alextu870719/Lab-Studio/releases/tag/$RELEASE_TAG${NC}"
echo -e "${BLUE}All releases: https://github.com/alextu870719/Lab-Studio/releases${NC}"
