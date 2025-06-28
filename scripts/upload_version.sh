#!/bin/bash

# Upload specific version to GitHub Releases
# Usage: ./upload_version.sh [version]

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get version from parameter or default to 1.0.1
VERSION=${1:-"1.0.1"}
VERSION_DIR="releases/v$VERSION"

echo -e "${BLUE}Upload Version $VERSION to GitHub Releases${NC}"

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

# Check if version directory exists
if [ ! -d "$VERSION_DIR" ]; then
    print_error "Version directory $VERSION_DIR not found"
    echo "Available versions:"
    ls -la releases/v* 2>/dev/null || echo "No version directories found"
    exit 1
fi

print_step "Checking version directory: $VERSION_DIR"
ls -la "$VERSION_DIR"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI not installed"
    echo "Please install GitHub CLI: brew install gh"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI not authenticated"
    echo "Please authenticate with GitHub: gh auth login"
    exit 1
fi

print_step "Preparing GitHub Release for v$VERSION"

RELEASE_TAG="v$VERSION"
RELEASE_TITLE="Lab Studio v$VERSION"
RELEASE_NOTES_FILE="$VERSION_DIR/RELEASE_NOTES_v$VERSION.md"

# Create release notes if it doesn't exist
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    print_step "Creating release notes"
    cat > "$RELEASE_NOTES_FILE" << EOF
# Lab Studio v$VERSION

## 🚀 新功能與改進

### 版本 $VERSION 更新內容
- PCR 試劑計算功能完善
- 使用者介面優化
- 多平台支援改進
- 效能提升和錯誤修正

## 📱 支援平台

此版本支援以下平台：
- **Android** (API 21+)
- **iOS** (iOS 12.0+) 
- **macOS** (macOS 10.14+)
- **Web** (現代瀏覽器)

## 📦 下載檔案說明

| 檔案類型 | 用途 | 安裝方式 |
|---------|------|----------|
| **android.apk** | Android 裝置直接安裝 | 下載後直接安裝 |
| **macos.tar.gz** | macOS 版本 | 解壓縮後執行 |
| **web.zip** | 網頁版本 | 解壓縮後部署到網頁伺服器 |

## 🛠️ 安裝說明

### Android
1. 下載 \`Lab-Studio-v$VERSION-android.apk\`
2. 在裝置上啟用「未知來源」安裝權限
3. 點擊 APK 檔案進行安裝

### macOS
1. 下載 \`Lab-Studio-v$VERSION-macos.tar.gz\`
2. 解壓縮檔案
3. 執行應用程式

### Web
1. 下載 \`Lab-Studio-v$VERSION-web.zip\`
2. 解壓縮到網頁伺服器目錄
3. 透過瀏覽器存取 \`index.html\`

## 📋 系統需求

- **Android**: Android 5.0 (API 21) 或更高版本
- **macOS**: macOS 10.14 或更高版本
- **Web**: Chrome 88+, Firefox 85+, Safari 14+, Edge 88+

## 🔗 相關連結

- [專案首頁](https://github.com/alextu870719/Lab-Studio)
- [使用說明](https://github.com/alextu870719/Lab-Studio/blob/main/README.md)
- [問題回報](https://github.com/alextu870719/Lab-Studio/issues)

---
📅 發布日期: $(date +"%Y-%m-%d")  
📦 Lab Studio - 專業實驗室計算工具
EOF
    print_success "Created release notes: $RELEASE_NOTES_FILE"
fi

# Collect all release files (excluding system files and directories)
RELEASE_FILES=()
for file in "$VERSION_DIR"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # Skip system files and README
        if [[ "$filename" != .DS_Store && "$filename" != *.md ]]; then
            RELEASE_FILES+=("$file")
        fi
    fi
done

if [ ${#RELEASE_FILES[@]} -eq 0 ]; then
    print_error "No release files found in $VERSION_DIR"
    exit 1
fi

echo "Found ${#RELEASE_FILES[@]} files to upload:"
for file in "${RELEASE_FILES[@]}"; do
    echo "  - $(basename "$file")"
done

# Check if release already exists
if gh release view "$RELEASE_TAG" &> /dev/null; then
    print_step "Updating existing release $RELEASE_TAG"
    
    echo -e "${YELLOW}Release $RELEASE_TAG already exists.${NC}"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作取消"
        exit 0
    fi
    
    # Upload all release files
    for file in "${RELEASE_FILES[@]}"; do
        filename=$(basename "$file")
        echo "Uploading $filename..."
        if gh release upload "$RELEASE_TAG" "$file" --clobber; then
            print_success "Uploaded $filename"
        else
            print_error "Failed to upload $filename"
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
    
    echo "Creating release with ${#RELEASE_FILES[@]} files..."
    
    if gh release create "$RELEASE_TAG" \
        --title "$RELEASE_TITLE" \
        --notes-file "$RELEASE_NOTES_FILE" \
        $RELEASE_OPTIONS \
        "${RELEASE_FILES[@]}"; then
        
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
print_success "GitHub Release upload completed!"
echo -e "${BLUE}Release URL: https://github.com/alextu870719/Lab-Studio/releases/tag/$RELEASE_TAG${NC}"
echo -e "${BLUE}All releases: https://github.com/alextu870719/Lab-Studio/releases${NC}"
