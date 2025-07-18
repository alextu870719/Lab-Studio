# Lab Studio v1.0.0 🧪

🎉 **首次發布！** Lab Studio 是一個專業的實驗室實驗設計和計算工具包，目前專注於 PCR 試劑計算。

## ✨ 主要功能

### 🧬 PCR 試劑計算器
- **銀行式數字輸入**：專業的千分位逗號格式化
- **智能體積計算**：自動計算多個反應的試劑用量
- **模板 DNA 管理**：靈活的模板 DNA 體積配置
- **可選試劑支援**：可切換試劑的包含/排除狀態
- **配置管理**：保存、載入和管理計算預設值

### 🎨 用戶體驗
- **現代化 UI/UX**：簡潔直觀的 iOS 風格介面
- **深色/淺色模式**：完整的主題切換支援
- **響應式設計**：適配各種螢幕尺寸
- **專業布局**：實驗室導向的設計模式

### 🔬 實驗追蹤
- **追蹤模式**：監控哪些試劑已添加到實驗中
- **雙重顯示選項**：
  - **Checkbox 模式**：視覺化勾選框追蹤
  - **Strikethrough 模式**：簡約的刪除線樣式
- **狀態管理**：跨會話的持久追蹤

### 📊 導出與分享
- **PDF 生成**：專業的計算報告
- **數據導出**：通過電子郵件、訊息等分享結果
- **列印支援**：直接列印功能

### ⚙️ 高級設定
- **主題偏好**：深色/淺色模式自動保存
- **顯示自定義**：選擇追蹤顯示樣式
- **配置備份**：保存/恢復應用程式配置

## 📱 支援平台

### ✅ 可用平台
- **Android** - APK 安裝包 (21 MB)
- **iOS** - IPA 安裝包 (22 MB) *需要側載或企業證書*
- **macOS** - DMG 安裝包 (19 MB)
- **Web** - 網頁應用程式 (7.6 MB) *可部署到任何網頁伺服器*
- **Linux** - TAR.GZ 安裝包 (20 MB) *使用 Docker 跨平台構建*

### ⏳ 即將支援
- **Windows** - 將在後續版本中支援

## 🚀 安裝指南

### Android
1. 下載 `Lab-Studio-1.0.0-android.apk`
2. 啟用 "未知來源" 安裝
3. 點擊 APK 檔案安裝

### iOS
1. 下載 `Lab-Studio-1.0.0-ios.ipa`
2. 使用 AltStore、Sideloadly 或企業證書安裝
3. 信任開發者證書

### macOS
1. 下載 `Lab-Studio-1.0.0-macos.dmg`
2. 開啟 DMG 檔案
3. 將應用程式拖拽到 Applications 資料夾
4. 右鍵點擊 -> 開啟（首次執行需要允許未識別開發者）

### Web
1. 下載 `Lab-Studio-1.0.0-web.zip`
2. 解壓縮到網頁伺服器目錄
3. 通過瀏覽器訪問 `index.html`

### Linux
1. 下載 `Lab-Studio-1.0.0-linux.tar.gz`
2. 解壓縮：`tar -xzf Lab-Studio-1.0.0-linux.tar.gz`
3. 進入目錄：`cd Lab-Studio-1.0.0-linux`
4. 執行：`./lab_studio`
5. 確保安裝 GTK3 依賴：`sudo apt install libgtk-3-0` (Ubuntu/Debian)

## 🔮 未來規劃

Lab Studio 設計為可擴展的實驗室工具平台：

- **🧪 額外計算器**：蛋白質純化、膠體電泳等
- **📋 協議管理**：逐步實驗協議
- **📊 數據分析**：內建統計分析工具
- **🔗 實驗室整合**：連接實驗設備和 LIMS
- **👥 團隊協作**：分享協議和結果
- **📈 進度追蹤**：實驗歷史和分析

## 🛠️ 技術規格

- **Framework**: Flutter 3.32.4
- **Language**: Dart
- **UI**: Cupertino (iOS-style)
- **Storage**: SharedPreferences
- **Export**: PDF generation
- **Compatibility**: iOS 11+, Android 5.0+, macOS 10.14+

## 🤝 貢獻

歡迎貢獻！請隨時提交 Issues、功能請求或 Pull Requests。

**Repository**: https://github.com/alextu870719/Lab-Studio

## 📄 授權

本專案採用 MIT 授權條款。

---

**Lab Studio** - 讓實驗室計算變得簡單、準確且專業。

🧬 為科學社群用心打造
