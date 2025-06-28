# Lab Studio v1.0.1 Release Notes

## 🎯 應用程式名稱修正版本

### ✅ 主要修正

**問題修復：**
- 修正了所有平台應用程式安裝或啟動後仍顯示舊名稱 "pcr_reagent_calculator" 的問題
- 現在所有平台都正確顯示 "Lab Studio" 作為應用程式名稱

### 🔧 平台特定修正

#### Android
- ✅ 更新 `AndroidManifest.xml` 中的 `android:label` 為 "Lab Studio"
- ✅ 應用程式安裝後在應用程式列表中顯示為 "Lab Studio"

#### iOS
- ✅ 更新 `Info.plist` 中的 `CFBundleDisplayName` 和 `CFBundleName` 為 "Lab Studio"
- ✅ 應用程式安裝後在主畫面顯示為 "Lab Studio"

#### macOS
- ✅ 更新 `Info.plist` 中的 `CFBundleDisplayName` 和 `CFBundleName` 為 "Lab Studio"
- ✅ 修正 Xcode 專案檔案中的產品引用
- ✅ 應用程式啟動後在 Dock 和選單欄中顯示為 "Lab Studio"

#### Windows
- ✅ 更新 `Runner.rc` 檔案中的產品資訊
- ✅ 修正 `main.cpp` 中的視窗標題為 "Lab Studio"
- ✅ 安裝程式和執行檔案資訊正確顯示 "Lab Studio"

#### Web
- ✅ 更新 `index.html` 中的 `<title>` 為 "Lab Studio"
- ✅ 修正 meta 標籤中的應用程式名稱
- ✅ 瀏覽器標籤頁顯示為 "Lab Studio"

#### Linux
- ✅ 更新 `CMakeLists.txt` 中的 `BINARY_NAME` 和 `APPLICATION_ID`
- ✅ 應用程式執行檔案名稱為 "lab_studio"

### 📦 發佈內容

- **Android**: `Lab-Studio-v1.0.1-android.apk` (22.2MB)
- **macOS**: `Lab-Studio-v1.0.1-macos.tar.gz` (52.9MB)
- **Web**: `Lab-Studio-v1.0.1-web.zip` (含完整 Web 應用程式)

### 🧪 測試建議

安裝或執行應用程式後，請確認：
1. 應用程式圖示下方顯示的名稱為 "Lab Studio"
2. 視窗標題欄顯示 "Lab Studio"
3. 任務管理器/活動監視器中顯示的進程名稱正確
4. 應用程式相關的所有 UI 元素都顯示正確名稱

### 💡 注意事項

- macOS 應用程式的檔案名稱在 Finder 中會顯示為 "Lab Studio.app"
- 所有平台的內部功能保持不變，僅修正了顯示名稱
- 建議卸載之前的版本後重新安裝以確保完全更新

---

**完整變更記錄請參考：** [GitHub Commits](https://github.com/alextu870719/Lab-Studio/commits/main)
