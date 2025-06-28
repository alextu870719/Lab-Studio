# 如何將Flutter Windows應用程式打包成單一exe檔案

## 目前的解決方案
目前提供的 `Lab-Studio-Standalone-v1.0.1.zip` 包含所有必要的檔案，解壓後即可運行。

## 創建真正的單一exe檔案的方法

### 方法1: 使用7-Zip (推薦)
1. 安裝7-Zip: `winget install 7zip.7zip`
2. 創建自解壓exe:
```cmd
cd build\windows\x64\runner\Release
7z a -sfx7z.sfx Lab-Studio-v1.0.1.exe *
```

### 方法2: 使用NSIS
1. 安裝NSIS (Nullsoft Scriptable Install System)
2. 創建NSIS腳本來打包所有檔案
3. 編譯成單一安裝程式

### 方法3: 使用UPX壓縮
UPX可以壓縮exe檔案，但無法合併依賴的dll檔案。

### 方法4: 使用flutter_distributor
```cmd
flutter pub global activate flutter_distributor
flutter_distributor package --platform windows --targets exe
```

## 為什麼Flutter Windows應用程式有多個檔案？
- `lab_studio.exe`: 主應用程式
- `flutter_windows.dll`: Flutter引擎
- `pdfium.dll`: PDF功能庫
- `printing_plugin.dll`: 列印功能庫
- `data/`: 應用程式資源

## 建議的分發方式
1. **便攜式zip檔** (目前方案) - 最簡單、最可靠
2. **安裝程式** - 使用NSIS或Inno Setup
3. **自解壓exe** - 使用7-Zip SFX

## 使用說明
下載 `Lab-Studio-Standalone-v1.0.1.zip` 後：
1. 解壓縮到任意資料夾
2. 雙擊 `lab_studio.exe` 即可運行
3. 所有檔案必須保持在同一資料夾中
