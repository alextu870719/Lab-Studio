#!/bin/bash

# Windows VM Setup Script for Flutter Development
# This script helps set up a Windows VM for building Flutter apps

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${YELLOW}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

echo -e "${BLUE}Flutter Windows Build - VM Setup Guide${NC}"
echo ""

print_step "檢查虛擬化選項"

# Check for Parallels Desktop
if command -v prlctl &> /dev/null; then
    print_success "發現 Parallels Desktop"
    echo "您可以使用 Parallels Desktop 建立 Windows VM"
    
    print_info "Parallels Desktop 設定步驟:"
    echo "1. 建立新的 Windows 11 虛擬機器"
    echo "2. 分配至少 8GB RAM 和 60GB 磁碟空間"
    echo "3. 啟用硬體加速"
    echo "4. 安裝 Parallels Tools"
    
elif command -v VBoxManage &> /dev/null; then
    print_success "發現 VirtualBox"
    echo "您可以使用 VirtualBox 建立 Windows VM"
    
    print_info "VirtualBox 設定步驟:"
    echo "1. 下載 Windows 11 ISO"
    echo "2. 建立新虛擬機器 (至少 8GB RAM, 60GB 磁碟)"
    echo "3. 啟用 VT-x/AMD-V 虛擬化"
    echo "4. 安裝 Guest Additions"
    
elif command -v qemu-system-x86_64 &> /dev/null; then
    print_success "發現 QEMU"
    echo "您可以使用 QEMU 建立 Windows VM"
    
else
    print_error "未發現虛擬化軟體"
    echo ""
    print_info "推薦的虛擬化解決方案:"
    echo "1. Parallels Desktop (付費，效能最佳) - brew install --cask parallels"
    echo "2. VirtualBox (免費) - brew install --cask virtualbox"
    echo "3. UTM (免費，基於 QEMU) - brew install --cask utm"
    echo ""
fi

print_step "Windows VM 中的 Flutter 設定"

cat << 'EOF'

在 Windows VM 中安裝以下軟體：

1. 安裝 Flutter SDK for Windows:
   - 下載: https://docs.flutter.dev/get-started/install/windows
   - 解壓縮到 C:\flutter
   - 將 C:\flutter\bin 加入 PATH

2. 安裝 Visual Studio 2022 Community:
   - 下載: https://visualstudio.microsoft.com/downloads/
   - 選擇 "Desktop development with C++" workload
   - 包含 Windows 10/11 SDK

3. 安裝 Git for Windows:
   - 下載: https://git-scm.com/download/win

4. 驗證安裝:
   在 PowerShell 中執行: flutter doctor

EOF

print_step "檔案同步方式"

cat << 'EOF'

將 macOS 專案同步到 Windows VM：

方法 1: 共享資料夾
- Parallels: 啟用共享資料夾功能
- VirtualBox: 設定共享資料夾
- UTM: 使用網路磁碟機

方法 2: Git 同步
- 在 macOS 上 push 到 GitHub
- 在 Windows VM 中 pull 最新版本

方法 3: SSH/SCP
- 使用 SSH 或 SCP 傳輸檔案

EOF

print_step "在 Windows VM 中建置"

cat << 'EOF'

在 Windows VM 的 PowerShell 中執行：

1. 清理並準備:
   flutter clean
   flutter pub get

2. 建置 Windows 應用程式:
   flutter build windows --release

3. 建立發布檔案:
   cd build\windows\x64\runner\Release
   Compress-Archive -Path .\* -DestinationPath Lab-Studio-windows.zip

4. 複製回 macOS:
   透過共享資料夾或 Git 將 ZIP 檔案傳回 macOS

EOF

print_step "自動化建議"

cat << 'EOF'

為了更方便的工作流程，建議：

1. 設定 SSH 存取 Windows VM
2. 建立自動化腳本在 VM 中建置
3. 使用 GitHub Actions (推薦)
4. 考慮使用雲端建置服務

EOF

print_info "如果您想使用 GitHub Actions 自動建置，請檢查專案中的 .github/workflows/build-windows.yml 檔案"

echo ""
print_success "設定指南完成！選擇最適合您的方案開始建置 Windows 應用程式。"
