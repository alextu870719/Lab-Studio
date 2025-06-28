#!/bin/bash

# Windows ARM VM File Transfer Script
# This script helps transfer files between macOS and Windows ARM VM

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //g' | sed 's/+.*//g')

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

echo -e "${BLUE}Windows ARM VM File Transfer Helper${NC}"
echo -e "${BLUE}Version: $VERSION${NC}"
echo ""

print_step "Windows ARM VM Setup Guide"

cat << 'EOF'

在您的 Windows ARM 虛擬機器中執行以下步驟：

1. 首次設定 Flutter 環境：
   - 複製所有腳本檔案到 Windows VM
   - 雙擊執行：run_windows_setup.bat (推薦)
   - 或以管理員身份執行 PowerShell：
     powershell -ExecutionPolicy Bypass -File .\windows_arm_setup.ps1

2. 建置應用程式：
   - 複製專案檔案到 Windows VM
   - 雙擊執行：run_windows_build.bat (推薦)
   - 或在 PowerShell 中執行：
     powershell -ExecutionPolicy Bypass -File .\windows_arm_build.ps1

EOF

print_step "檔案傳輸方式"

echo "選擇您偏好的檔案傳輸方式："
echo "1. 共享資料夾 (推薦)"
echo "2. SCP/SFTP"
echo "3. GitHub 同步"
echo "4. 網路磁碟機"
echo ""

read -p "請選擇 (1-4): " choice

case $choice in
    1)
        print_step "共享資料夾設定"
        cat << 'EOF'

根據您的虛擬機器軟體設定共享資料夾：

Parallels Desktop:
1. 虛擬機器 > 設定 > 選項 > 共享
2. 啟用「共享 Mac 資料夾」
3. 選擇要共享的資料夾（如專案根目錄）
4. 在 Windows 中存取 \\Mac\共享資料夾名稱

VMware Fusion:
1. 虛擬機器 > 設定 > 共享
2. 啟用共享資料夾
3. 新增 macOS 資料夾
4. 在 Windows 中存取網路位置

VirtualBox:
1. 設定 > 共享資料夾
2. 新增共享資料夾
3. 在 Windows 中執行：net use Z: \\vboxsrv\sharename

EOF
        ;;
    2)
        print_step "SCP/SFTP 設定"
        cat << 'EOF'

設定 SSH 存取：

在 Windows VM 中：
1. 啟用 OpenSSH Server：
   設定 > 應用程式 > 可選功能 > 新增功能 > OpenSSH 伺服器

2. 啟動 SSH 服務：
   services.msc > OpenSSH SSH Server > 啟動

3. 設定防火牆規則允許 SSH (連接埠 22)

在 macOS 中傳輸檔案：
scp -r . username@vm-ip:C:/dev/Lab-Studio/
scp username@vm-ip:C:/dev/Lab-Studio/releases/*.zip ./releases/

EOF
        ;;
    3)
        print_step "GitHub 同步設定"
        cat << 'EOF'

使用 Git 同步專案：

在 macOS 中：
git add .
git commit -m "Prepare for Windows build"
git push origin main

在 Windows VM 中：
git clone https://github.com/alextu870719/Lab-Studio.git
cd Lab-Studio
# 或者如果已經 clone：
git pull origin main

建置完成後，將 releases 檔案複製回 macOS：
- 可以透過共享資料夾
- 或者建立新的 commit 並推送

EOF
        ;;
    4)
        print_step "網路磁碟機設定"
        cat << 'EOF'

設定網路磁碟機：

在 macOS 中：
1. 系統偏好設定 > 共享
2. 啟用「檔案共享」
3. 新增要共享的資料夾
4. 記下 macOS 的 IP 位址

在 Windows VM 中：
1. 開啟檔案總管
2. 點擊「本機」
3. 點擊「連接網路磁碟機」
4. 輸入：\\macos-ip\共享資料夾名稱
5. 輸入 macOS 使用者憑證

EOF
        ;;
    *)
        print_error "無效選擇"
        exit 1
        ;;
esac

print_step "建議的工作流程"

cat << EOF

推薦的開發流程：

1. 在 macOS 中開發和測試
2. 使用 Git 或共享資料夾同步到 Windows VM
3. 在 Windows VM 中執行：
   .\windows_arm_build.ps1
4. 將建置的 ZIP 檔案複製回 macOS
5. 上傳到 GitHub Releases

建置檔案位置：
Windows: C:\path\to\project\releases\Lab-Studio-v$VERSION-windows-arm64.zip
macOS: ./releases/Lab-Studio-v$VERSION-windows-arm64.zip

EOF

# Create PowerShell scripts for easy transfer
print_step "建立 PowerShell 腳本"

# Check if we should copy scripts to a transfer directory
if [ -d "/Volumes" ]; then
    # Look for mounted Windows VM volumes
    VM_MOUNTS=$(ls /Volumes/ | grep -i "windows\|vm\|parallels" || true)
    if [ -n "$VM_MOUNTS" ]; then
        echo "發現可能的 VM 掛載點："
        echo "$VM_MOUNTS"
        echo ""
        read -p "要將 PowerShell 腳本複製到掛載的 VM 嗎？(y/N): " copy_scripts
        if [[ $copy_scripts =~ ^[Yy]$ ]]; then
            for mount in $VM_MOUNTS; do
                MOUNT_PATH="/Volumes/$mount"
                if [ -w "$MOUNT_PATH" ]; then
                    cp scripts/windows_arm_setup.ps1 "$MOUNT_PATH/" 2>/dev/null || true
                    cp scripts/windows_arm_build.ps1 "$MOUNT_PATH/" 2>/dev/null || true
                    cp scripts/run_windows_setup.bat "$MOUNT_PATH/" 2>/dev/null || true
                    cp scripts/run_windows_build.bat "$MOUNT_PATH/" 2>/dev/null || true
                    cp scripts/WINDOWS_EXECUTION_POLICY.md "$MOUNT_PATH/" 2>/dev/null || true
                    print_success "腳本已複製到 $MOUNT_PATH"
                fi
            done
        fi
    fi
fi

print_step "腳本使用說明"

cat << 'EOF'

在 Windows ARM VM 中：

1. 首次設定（推薦使用批次檔）：
   雙擊：run_windows_setup.bat
   或：powershell -ExecutionPolicy Bypass -File .\windows_arm_setup.ps1

2. 建置應用程式：
   雙擊：run_windows_build.bat
   或：powershell -ExecutionPolicy Bypass -File .\windows_arm_build.ps1

3. 如果遇到執行政策問題，請參考：
   WINDOWS_EXECUTION_POLICY.md 檔案

4. 可選參數（只適用於 PowerShell 執行）：
   .\windows_arm_build.ps1 -Version "1.0.1"
   .\windows_arm_build.ps1 -SkipClean

EOF

print_success "檔案傳輸設定完成！"
print_info "請依照上述步驟在 Windows ARM VM 中設定 Flutter 環境並建置應用程式。"
