#!/bin/bash

# Build Windows App via GitHub Actions
# This script triggers a Windows build using GitHub Actions

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

echo -e "${BLUE}Windows Build via GitHub Actions${NC}"
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

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI 未安裝"
    echo "請安裝 GitHub CLI: brew install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI 未驗證"
    echo "請執行: gh auth login"
    exit 1
fi

print_step "檢查 GitHub Actions 工作流程"

# Check if workflow exists
if ! gh workflow list | grep -q "Build Windows App"; then
    print_error "找不到 Windows 建置工作流程"
    echo "請確認 .github/workflows/build-windows.yml 檔案存在"
    exit 1
fi

print_step "推送最新變更到 GitHub"

# Check if there are uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}發現未提交的變更，正在提交...${NC}"
    git add .
    git commit -m "Update for Windows build v$VERSION" || true
fi

# Push to GitHub
if git push origin main; then
    print_success "程式碼已推送到 GitHub"
else
    print_error "推送失敗"
    exit 1
fi

print_step "觸發 Windows 建置"

# Trigger the workflow
if gh workflow run build-windows.yml -f version="$VERSION"; then
    print_success "Windows 建置工作流程已觸發"
    
    echo ""
    echo -e "${BLUE}建置資訊：${NC}"
    echo "• 版本: $VERSION"
    echo "• 平台: Windows x64"
    echo "• 建置類型: Release"
    
    echo ""
    echo -e "${YELLOW}請前往以下連結查看建置進度：${NC}"
    echo "https://github.com/alextu870719/Lab-Studio/actions"
    
    echo ""
    echo -e "${BLUE}建置完成後：${NC}"
    echo "1. 前往 Actions 頁面"
    echo "2. 點擊最新的 'Build Windows App' 工作流程"
    echo "3. 在 Artifacts 區域下載 Windows 應用程式"
    echo "4. 或者檢查是否自動建立了新的 Release"
    
    # Wait a moment and check workflow status
    echo ""
    print_step "等待工作流程開始..."
    sleep 5
    
    # Get the latest workflow run
    WORKFLOW_URL=$(gh run list --workflow=build-windows.yml --limit=1 --json url --jq '.[0].url')
    if [ -n "$WORKFLOW_URL" ]; then
        echo -e "${GREEN}工作流程已開始！${NC}"
        echo -e "${BLUE}直接連結: $WORKFLOW_URL${NC}"
        
        # Ask if user wants to monitor the workflow
        echo ""
        read -p "要即時監控建置進度嗎？(y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "監控建置進度 (按 Ctrl+C 退出)..."
            gh run watch
        fi
    fi
    
else
    print_error "無法觸發工作流程"
    echo "請檢查："
    echo "1. GitHub Actions 是否已啟用"
    echo "2. 工作流程檔案是否正確"
    echo "3. 您是否有倉庫的寫入權限"
    exit 1
fi

echo ""
print_success "Windows 建置流程已開始！"
echo -e "${BLUE}建置通常需要 5-10 分鐘完成${NC}"
