# Lab Studio v1.0.1 Release Notes 

## 🎯 應用程式名稱修正版本 + Windows桌面應用程式

### ✨ 新增功能
- **🖥️ Windows桌面應用程式**: 完整的原生Windows應用程式，無需額外安裝依賴項
- **📱 跨平台支援**: Android、iOS、macOS、Windows、Web、Linux全平台支援

### ✅ 主要修正
**問題修復**：
• 修正了所有平台應用程式安裝或啟動後仍顯示舊名稱 "pcr_reagent_calculator" 的問題
• 現在所有平台都正確顯示 "Lab Studio" 作為應用程式名稱

### 🔧 平台特定修正

#### 🖥️ Windows (新增)
• ✅ 完整的原生桌面應用程式
• ✅ 獨立執行檔，無需安裝Flutter或其他依賴項
• ✅ 支援Windows 10及更新版本（64位）
• ✅ 完整的GUI界面和所有功能
• ✅ 內建PDF匯出和列印功能
• ✅ 檔案大小：約13.9MB（壓縮後）

#### Android
• ✅ 更新 AndroidManifest.xml 中的 android:label 為 "Lab Studio"
• ✅ 應用程式安裝後在應用程式列表中顯示為 "Lab Studio"

#### iOS
• ✅ 更新 Info.plist 中的 CFBundleDisplayName 和 CFBundleName 為 "Lab Studio"
• ✅ 應用程式安裝後在主畫面顯示為 "Lab Studio"

#### macOS
• ✅ 更新 Info.plist 中的 CFBundleDisplayName 和 CFBundleName 為 "Lab Studio"
• ✅ 修正 Xcode 專案檔案中的產品引用
• ✅ 應用程式啟動後在 Dock 和選單欄中顯示為 "Lab Studio"

#### Web
• ✅ 更新 index.html 中的 <title> 為 "Lab Studio"
• ✅ 修正 meta 標籤中的應用程式名稱
• ✅ 瀏覽器標籤頁顯示為 "Lab Studio"

#### Linux
• ✅ 更新 CMakeLists.txt 中的 BINARY_NAME 和 APPLICATION_ID
• ✅ 應用程式執行檔案名稱為 "lab_studio"

### 📦 發佈內容
- **Android**: Lab-Studio-v1.0.1-android.apk (22.2MB)
- **macOS**: Lab-Studio-v1.0.1-macos.tar.gz (52.9MB)  
- **Windows安裝程式**: Lab-Studio-v1.0.1-Windows-Installer.exe (11.8MB) 🆕
- **Windows便攜式**: Lab-Studio-v1.0.1-Windows-Portable.zip (13.9MB) 🆕
- **Web**: Lab-Studio-v1.0.1-web.zip (含完整 Web 應用程式)

### 🖥️ Windows版本詳細說明
**系統需求**：
- Windows 10 或更新版本
- 64位作業系統
- 約30MB可用磁碟空間

**安裝說明**：

**🖥️ 安裝程式版本（推薦）**：
1. 下載 `Lab-Studio-v1.0.1-Windows-Installer.exe`
2. 執行安裝程式，按照指示完成安裝
3. 從桌面或開始選單啟動應用程式

**📦 便攜式版本**：
1. 下載 `Lab-Studio-v1.0.1-Windows-Portable.zip`
2. 解壓縮到任意資料夾
3. 雙擊 `lab_studio.exe` 即可啟動

**包含文件**：
- `lab_studio.exe`: 主執行檔 (90KB)
- `flutter_windows.dll`: Flutter運行時庫 (19MB)
- `pdfium.dll`: PDF處理庫 (4.7MB)
- `printing_plugin.dll`: 列印功能插件 (139KB)
- `data/`: 應用程式資源文件夾
- `README.txt`: 詳細使用說明

### 🧪 測試建議
安裝或執行應用程式後，請確認：
1. 應用程式圖示下方顯示的名稱為 "Lab Studio"
2. 視窗標題欄顯示 "Lab Studio"
3. 任務管理器/活動監視器中顯示的進程名稱正確
4. 應用程式相關的所有 UI 元素都顯示正確名稱

### 💡 注意事項
- macOS 應用程式的檔案名稱在 Finder 中會顯示為 "Lab Studio.app"
- Windows版本首次啟動可能需要幾秒鐘載入時間
- 某些防毒軟體可能需要添加例外
- 所有平台的內部功能保持不變，僅修正了顯示名稱

---
**構建日期**: 2025年6月28日  
**版本**: 1.0.1  
**支援平台**: Windows, macOS, iOS, Android, Web, Linux  

完整變更記錄請參考：[GitHub Commits](https://github.com/alextu870719/Lab-Studio/commits/main)
