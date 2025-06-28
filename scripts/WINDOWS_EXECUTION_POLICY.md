# Windows PowerShell 執行政策解決方案

## 問題
```
.\windows_arm_setup.ps1 : File cannot be loaded because running scripts is disabled on this system.
```

## 解決方案

### 方法 1: 一次性執行 (推薦)
在 PowerShell 中執行以下命令來一次性允許腳本執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\windows_arm_setup.ps1
```

### 方法 2: 設定使用者執行政策
為當前使用者設定執行政策：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

然後執行腳本：
```powershell
.\windows_arm_setup.ps1
```

### 方法 3: 管理員權限設定 (永久解決)
以**管理員身份**執行 PowerShell，然後執行：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### 方法 4: 解除封鎖檔案
如果檔案被 Windows 封鎖，執行：

```powershell
Unblock-File -Path .\windows_arm_setup.ps1
Unblock-File -Path .\windows_arm_build.ps1
```

## 執行政策說明

- **Restricted**: 預設值，不允許執行任何腳本
- **RemoteSigned**: 允許本地腳本和已簽名的遠端腳本執行
- **Unrestricted**: 允許所有腳本執行（不推薦）

## 完整執行步驟

1. 右鍵點擊「開始」選單，選擇「Windows PowerShell (管理員)」
2. 執行以下命令之一：

**一次性執行**：
```powershell
cd C:\Users\chi-kuantu\Desktop
powershell -ExecutionPolicy Bypass -File .\windows_arm_setup.ps1
```

**或設定政策後執行**：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
cd C:\Users\chi-kuantu\Desktop
.\windows_arm_setup.ps1
```

## 安全提醒

- 只執行您信任的腳本
- 建議使用 `RemoteSigned` 而不是 `Unrestricted`
- 可以在完成後重設為 `Restricted` 以提高安全性

## 如果仍有問題

如果上述方法都無法解決，請嘗試：

1. 確認您有管理員權限
2. 檢查檔案是否被防毒軟體阻擋
3. 手動複製腳本內容到 PowerShell 中執行
4. 使用 Windows 內建的「以管理員身分執行」選項
