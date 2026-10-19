Unicode true
!include "MUI2.nsh"
!include "x64.nsh"
!ifndef VERSION
  !error "Pass /DVERSION or -DVERSION"
!endif
Name "苔光遗境 · Mosslight"
OutFile "../../builds/distribution/Mosslight-${VERSION}-Windows-x64-Setup.exe"
InstallDir "$LOCALAPPDATA\Programs\Mosslight"
InstallDirRegKey HKCU "Software\Mosslight" "InstallLocation"
RequestExecutionLevel user
ManifestDPIAware true
SetCompressor /SOLID lzma
VIProductVersion "0.1.0.0"
VIAddVersionKey /LANG=2052 "ProductName" "苔光遗境 · Mosslight"
VIAddVersionKey /LANG=2052 "FileDescription" "Mosslight 安装程序"
VIAddVersionKey /LANG=2052 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=2052 "LegalCopyright" "Mosslight"
!define MUI_ICON "../../builds/icon.ico"
!define MUI_UNICON "../../builds/icon.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "欢迎来到苔光遗境"
!define MUI_WELCOMEPAGE_TEXT "安装原生 Windows 版 Mosslight。$\r$\n$\r$\n无需安装 Godot；支持键盘与手柄。$\r$\n$\r$\n这是开发测试版。"
!define MUI_FINISHPAGE_RUN "$INSTDIR\Mosslight.exe"
!define MUI_FINISHPAGE_RUN_TEXT "启程，探索苔光遗境"
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "Mosslight requires 64-bit Windows."
    Abort
  ${EndIf}
FunctionEnd

Section "Mosslight"
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File "../../builds/windows/Mosslight.exe"
  File "../../builds/windows/README.txt"
  File "../../builds/windows/THIRD_PARTY_NOTICES.md"
  SetOutPath "$INSTDIR\licenses"
  File "../../builds/windows/licenses/*.txt"
  SetOutPath "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\Mosslight"
  CreateShortCut "$SMPROGRAMS\Mosslight\苔光遗境.lnk" "$INSTDIR\Mosslight.exe"
  CreateShortCut "$SMPROGRAMS\Mosslight\卸载 Mosslight.lnk" "$INSTDIR\Uninstall.exe"
  CreateShortCut "$DESKTOP\苔光遗境.lnk" "$INSTDIR\Mosslight.exe"
  WriteRegStr HKCU "Software\Mosslight" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "DisplayName" "苔光遗境 · Mosslight"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "Publisher" "Mosslight"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "DisplayIcon" "$INSTDIR\Mosslight.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "QuietUninstallString" '$\"$INSTDIR\Uninstall.exe$\" /S'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$INSTDIR\Mosslight.exe"
  Delete "$INSTDIR\README.txt"
  Delete "$INSTDIR\THIRD_PARTY_NOTICES.md"
  Delete "$INSTDIR\licenses\Noto-OFL.txt"
  Delete "$INSTDIR\licenses\Godot-MIT.txt"
  Delete "$INSTDIR\licenses\Godot-ThirdParty.txt"
  RMDir "$INSTDIR\licenses"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\Mosslight\苔光遗境.lnk"
  Delete "$SMPROGRAMS\Mosslight\卸载 Mosslight.lnk"
  RMDir "$SMPROGRAMS\Mosslight"
  Delete "$DESKTOP\苔光遗境.lnk"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Mosslight"
  DeleteRegKey HKCU "Software\Mosslight"
SectionEnd
