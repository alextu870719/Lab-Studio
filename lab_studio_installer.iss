[Setup]
; 基本設定
AppName=Lab Studio
AppVersion=1.0.1
AppPublisher=Lab Studio Team
AppPublisherURL=https://github.com/alextu870719/Lab-Studio
AppSupportURL=https://github.com/alextu870719/Lab-Studio/issues
AppUpdatesURL=https://github.com/alextu870719/Lab-Studio/releases
DefaultDirName={autopf}\Lab Studio
DefaultGroupName=Lab Studio
AllowNoIcons=yes
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
OutputDir=installer_output
OutputBaseFilename=Lab-Studio-v1.0.1-Windows-Installer
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; 系統需求
MinVersion=10.0
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; 權限
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; 主執行檔
Source: "build\windows\x64\runner\Release\lab_studio.exe"; DestDir: "{app}"; Flags: ignoreversion
; Flutter DLL
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
; PDF處理庫
Source: "build\windows\x64\runner\Release\pdfium.dll"; DestDir: "{app}"; Flags: ignoreversion
; 列印插件
Source: "build\windows\x64\runner\Release\printing_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
; 資源文件夾
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; 說明文件
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion; DestName: "README.txt"

[Icons]
Name: "{group}\Lab Studio"; Filename: "{app}\lab_studio.exe"
Name: "{group}\{cm:ProgramOnTheWeb,Lab Studio}"; Filename: "https://github.com/alextu870719/Lab-Studio"
Name: "{group}\{cm:UninstallProgram,Lab Studio}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Lab Studio"; Filename: "{app}\lab_studio.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\Lab Studio"; Filename: "{app}\lab_studio.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\lab_studio.exe"; Description: "{cm:LaunchProgram,Lab Studio}"; Flags: nowait postinstall skipifsilent

[Registry]
; 註冊應用程式以供控制面板顯示
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{{#StringChange(AppId, '{', '')}}"; ValueType: string; ValueName: "DisplayName"; ValueData: "{#AppName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{{#StringChange(AppId, '{', '')}}"; ValueType: string; ValueName: "DisplayVersion"; ValueData: "{#AppVersion}"
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{{#StringChange(AppId, '{', '')}}"; ValueType: string; ValueName: "Publisher"; ValueData: "{#AppPublisher}"

[Code]
// 自定義安裝檢查
function InitializeSetup(): Boolean;
begin
  Result := True;
  if not IsDotNetInstalled(net462, 0) then
  begin
    MsgBox('此應用程式需要 .NET Framework 4.6.2 或更新版本。' + #13#10 + 
           '請先安裝 .NET Framework 後再運行此安裝程式。', mbError, MB_OK);
    Result := False;
  end;
end;

// 安裝完成後的訊息
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // 這裡可以添加安裝後的設定
  end;
end;
