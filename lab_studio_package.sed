[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles

[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=Lab Studio portable application has been extracted and launched.
TargetName=C:\Users\chi-kuantu\Lab-Studio\Lab-Studio-Portable-v1.0.1.exe
FriendlyName=Lab Studio v1.0.1
AppLaunched=lab_studio.exe
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="lab_studio.exe"
FILE1="flutter_windows.dll"
FILE2="pdfium.dll"
FILE3="printing_plugin.dll"
FILE4="data"

[SourceFiles]
SourceFiles0=C:\Users\chi-kuantu\Lab-Studio\build\windows\x64\runner\Release\

[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
%FILE3%=
%FILE4%=
