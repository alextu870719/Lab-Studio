# Lab Studio 建置和發布指南

本專案提供了多種方式來建置 Lab Studio 應用程式並自動將輸出檔案複製到 releases 資料夾。

## 快速開始

### 方法 1: 使用 Make 命令 (推薦)

```bash
# 建置所有平台並上傳到 GitHub Releases
make release

# 只建置所有平台 (不上傳)
make all

# 只建置 Android APK
make android

# 只建置 iOS (僅限 macOS)
make ios

# 只建置 macOS (僅限 macOS)
make macos

# 只建置 Web
make web

# 上傳現有的 release 檔案到 GitHub
make github-upload

# 設定 GitHub CLI (如果尚未設定)
make github-setup

# 清理建置檔案
make clean

# 查看所有可用命令
make help
```

### 方法 2: 直接運行腳本

```bash
# 建置所有平台並自動上傳到 GitHub Releases
./scripts/build_and_release.sh

# 只上傳現有檔案到 GitHub Releases
./scripts/github_release.sh

# 快速建置 Android
./scripts/quick_build_android.sh

# 建置 iOS
./scripts/build_ios.sh

# 建置 macOS
./scripts/build_macos.sh

# 建置 Web
./scripts/build_web.sh
```

### 方法 3: 使用 VS Code 任務

1. 按 `Cmd+Shift+P` (macOS) 或 `Ctrl+Shift+P` (Windows/Linux)
2. 輸入 "Tasks: Run Task"
3. 選擇想要執行的建置任務：
   - **Build and Upload to GitHub** - 建置並上傳到 GitHub Releases
   - Build All Platforms - 建置所有平台
   - Upload to GitHub Releases - 只上傳現有檔案
   - Quick Build Android
   - Build iOS
   - Build macOS
   - Build Web

## GitHub Releases 自動上傳

### 設定 GitHub CLI (首次使用)

如果您還沒有設定 GitHub CLI：

```bash
# 安裝 GitHub CLI (如果尚未安裝)
brew install gh

# 或使用 make 命令一次完成設定
make github-setup
```

### 使用 GitHub Releases

系統提供三種 Release 發布選項：

1. **Draft Release (草稿)** - 預設選項，可以預覽後再發布
2. **Pre-release (預發布)** - 標記為測試版本
3. **Public Release (公開發布)** - 立即公開發布

### 自動功能

- 自動從 `pubspec.yaml` 讀取版本號
- 自動創建 Release Notes
- 支援更新現有 Release
- 自動上傳所有平台的建置檔案
- 提供完整的下載說明和系統需求

## 輸出檔案

所有建置完成的檔案會自動複製到 `releases/` 資料夾，檔案命名格式：
- `Lab-Studio-{版本}-android.apk` - Android APK
- `Lab-Studio-{版本}-android.aab` - Android App Bundle
- `Lab-Studio-{版本}-ios.ipa` - iOS IPA
- `Lab-Studio-{版本}-macos.dmg` - macOS DMG (需要 create-dmg)
- `Lab-Studio-{版本}-macos.zip` - macOS ZIP (備用格式)
- `Lab-Studio-{版本}-web.zip` - Web 應用程式
- `Lab-Studio-{版本}-linux.tar.gz` - Linux 應用程式
- `Lab-Studio-{版本}-windows.zip` - Windows 應用程式

## 系統需求

### 所有平台
- Flutter SDK
- Dart SDK

### Android
- Android SDK
- Android Studio 或 Command Line Tools

### iOS (僅限 macOS)
- Xcode
- iOS SDK
- 有效的 iOS 開發者帳號 (用於發布)

### macOS (僅限 macOS)
- Xcode
- 建議安裝 `create-dmg` 來產生更好的 DMG 檔案：
  ```bash
  brew install create-dmg
  # 或使用
  make install-deps
  ```

### Web
- 無額外需求

## 版本管理

版本號碼從 `pubspec.yaml` 檔案中自動讀取。要更新版本：

1. 編輯 `pubspec.yaml`
2. 修改 `version:` 行，例如：`version: 1.0.1+2`
3. 運行建置腳本，檔案會以新版本號命名

## 故障排除

### 權限問題
如果腳本無法執行，請確保有執行權限：
```bash
chmod +x scripts/*.sh
```

### 建置失敗
1. 確保所有依賴項目都已安裝
2. 運行 `flutter doctor` 檢查環境
3. 嘗試 `make clean` 清理建置檔案

### macOS DMG 建立失敗
如果 DMG 建立失敗，腳本會自動建立 ZIP 檔案作為備用。要獲得更好的 DMG 支援：
```bash
brew install create-dmg
```

## 自動化 CI/CD

這些腳本可以輕鬆整合到 CI/CD 管道中，例如 GitHub Actions、GitLab CI 或 Jenkins。

範例 GitHub Actions 設定：
```yaml
- name: Build and Release
  run: |
    chmod +x scripts/*.sh
    ./scripts/build_and_release.sh
```

## 貢獻

如果您有改善建置流程的建議，歡迎提交 Pull Request 或開啟 Issue。
