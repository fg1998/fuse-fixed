## NSIS (nsis.sf.net) script to produce installer for win32 platform
## Copyright (c) 2009 Marek Januszewski
## Copyright (c) 2016 Sergio Baldoví

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program; if not, write to the Free Software Foundation, Inc.,
## 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
##
## Author contact information:
##
## E-mail: philip-fuse@shadowmagic.org.uk

!define FUSE_VERSION "1.5.7" ; could have letters like -RC1
!define FUSE_FULL_VERSION "1.5.7.0" ; must have four numeric tokens
!define DISPLAY_NAME "the Free Unix Spectrum Emulator (Fuse) ${FUSE_VERSION}"
!define SETUP_FILENAME "fuse-${FUSE_VERSION}-win32-setup"
!define SETUP_FILE "${SETUP_FILENAME}.exe"
!define HKLM_REG_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Fuse"
!define PROG_ID "Fuse.Files.1"

;Include Modern UI
!include "MUI2.nsh"
!include "Sections.nsh"
!include "Util.nsh"

;--------------------------------
;General

Name "${DISPLAY_NAME}"
outFile "${SETUP_FILE}"
Caption "${DISPLAY_NAME}"
 
installDir "$PROGRAMFILES\Fuse"

; [Additional Installer Settings ]
XPStyle on
SetCompress force
SetCompressor lzma

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !define MUI_LICENSEPAGE_BUTTON "Next >"
  !define MUI_LICENSEPAGE_TEXT_BOTTOM "$(^Name) is released under the GNU General Public License (GPL). The license is provided here for information purposes only. $_CLICK"
  !insertmacro MUI_PAGE_LICENSE "COPYING.txt"

  !define MUI_COMPONENTSPAGE_SMALLDESC
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !define MUI_FINISHPAGE_RUN "$INSTDIR\fuse.exe"
  !define MUI_FINISHPAGE_NOREBOOTSUPPORT
  !insertmacro MUI_PAGE_FINISH
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !define MUI_FINISHPAGE_SHOWREADME_CHECKED
  !define MUI_FINISHPAGE_SHOWREADME ""
  !define MUI_FINISHPAGE_SHOWREADME_TEXT "Delete configuration file"
  !define MUI_FINISHPAGE_SHOWREADME_FUNCTION un.DeleteConfigFile
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages
 
  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Version Information

  VIProductVersion ${FUSE_FULL_VERSION}
  VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" ""
  VIAddVersionKey /LANG=${LANG_ENGLISH} "InternalName" "${SETUP_FILENAME}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "(c) 1999-2018 Philip Kendall and others"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Fuse"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${FUSE_VERSION}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "OriginalFilename" "${SETUP_FILE}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "Fuse - the Free Unix Spectrum Emulator"
  VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${FUSE_VERSION}"

;--------------------------------
;File association functions

!macro SelectUnregisteredExtCall _EXTENSION _SECTION
  Push `${_EXTENSION}`
  Push `${_SECTION}`
  ${CallArtificialFunction} SelectUnregisteredExt_
!macroend

!macro NewSecExtensionCall _EXTENSION _DESCRIPTION
  Section /o "${_DESCRIPTION} File" SEC_${_DESCRIPTION}
    ${registerExtension} "${_EXTENSION}"
  SectionEnd
!macroend

!macro RegisterExtensionCall _EXTENSION
  Push `${_EXTENSION}`
  ${CallArtificialFunction} RegisterExtension_
!macroend

!macro UnRegisterExtensionCall _EXTENSION
  Push "${_EXTENSION}"
  ${CallArtificialFunction} UnRegisterExtension_
!macroend

!macro SelectUnregisteredExt_
  Exch $R1 ;section
  Exch
  Exch $R0 ;extension
  Exch
  Push $0

  ReadRegStr $0 HKLM "Software\Classes\$R0" ""
  ;Select if already associated with FUSE, i.e., reinstallation
  StrCmp $0 "${PROG_ID}" Select 0 
  ;Select if available
  StrCmp $0 "" Select NoSelect

Select:
  !insertmacro SelectSection $R1

NoSelect:
  Pop $0
  Pop $R1
  Pop $R0
!macroend

!macro RegisterExtension_
  Exch $R0 ;extension
  Push $0

  ; Recommend Fuse in the Open With list
  WriteRegStr HKLM "Software\Classes\$R0\OpenWithProgids" "${PROG_ID}" ""

  ; Read global file association
  ReadRegStr $0 HKLM "Software\Classes\$R0" ""
  StrCmp "$0" "" NoBackup  ; is it empty
  StrCmp "$0" "${PROG_ID}" NoBackup ; is it our own
  ; Backup current value
  WriteRegStr HKLM "Software\Classes\$R0" "backup_val" "$0"

NoBackup:
  ; Set global file association
  WriteRegStr HKLM "Software\Classes\$R0" "" "${PROG_ID}"

  ; Set current user (custom) file association
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0" "Progid"
  StrCmp "$0" "" NoLocalBackup ; is it empty
  StrCmp "$0" "${PROG_ID}" NoLocalBackup ; is it our own
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0" "backup_val" "$0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0" "Progid" "${PROG_ID}"

NoLocalBackup:
  Pop $0
  Pop $R0
!macroend

!macro UnRegisterExtension_
  Exch $R0 ;extension
  Push $0

  ; Unregister OpenWith recommendation
  DeleteRegValue HKLM "Software\Classes\$R0\OpenWithProgids" "${PROG_ID}"

  ; Try to delete current file association
  ReadRegStr $0 HKLM "Software\Classes\$R0" ""
  StrCmp $0 ${PROG_ID} 0 NoOwn ; only do this if we own it
  ReadRegStr $0 HKLM "Software\Classes\$R0" "backup_val"
  StrCmp $0 "" 0 Restore ; if backup="" then delete the whole key
  DeleteRegKey HKLM "Software\Classes\$R0"
  Goto NoOwn

Restore:
  WriteRegStr HKLM "Software\Classes\$R0" "" $0
  DeleteRegValue HKLM "Software\Classes\$R0" "backup_val"

NoOwn:
  ; Delete programmatic identifier
  DeleteRegKey HKLM "Software\Classes\${PROG_ID}";

  ; Delete current user (custom) file association
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0" "Progid"
  StrCmp "$0" "" NoLocalRestore ; is it empty
  StrCmp "$0" "${PROG_ID}" 0 NoLocalRestore ; is it our own
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0" "backup_val"
  StrCmp "$0" "" 0 +2 ; if no backup -> delete
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0" "Progid" "$0"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$R0" "backup_val"

NoLocalRestore:
  Pop $0
  Pop $R0
!macroend

!define NewSecExtension `!insertmacro NewSecExtensionCall`
!define SelectUnregisteredExt `!insertmacro SelectUnregisteredExtCall`
!define RegisterExtension `!insertmacro RegisterExtensionCall`
!define UnRegisterExtension `!insertmacro UnRegisterExtensionCall`

;--------------------------------
; Uninstall previous version

 Section "" SecUninstallPrevious

    Push $R0
    ReadRegStr $R0 HKLM "${HKLM_REG_KEY}" "UninstallString"

    ; Check if we are upgrading a previous installation
    ${If} $R0 == '"$INSTDIR\uninstall.exe"'
        DetailPrint "Removing previous installation..."

        ; Run the uninstaller silently
        ExecWait '"$INSTDIR\uninstall.exe" /S _?=$INSTDIR'
    ${EndIf}

    Pop $R0

SectionEnd

;--------------------------------
; start default section

section "!Fuse Core Files (required)" SecCore

    SectionIn RO
    DetailPrint "Installing Fuse Core Files..."
 
    ; set the installation directory as the destination for the following actions
    setOutPath "$INSTDIR"

    ; Installation files
    File "AUTHORS.txt"
    File "ChangeLog.txt"
    File "COPYING.txt"
    File "fuse.exe"
    File "fuse.html"
    File /nonfatal "LICENSES.txt"
    File /nonfatal "manual*.png"
    File "README.txt"
    File /nonfatal "README-win32.txt"
    File "*.dll"
    SetOutPath $INSTDIR\3rd-party
    File /nonfatal "3rd-party\*"
    SetOutPath $INSTDIR\lib
    File "lib\*"
    SetOutPath "$INSTDIR\roms"
    File "roms\*"
    SetOutPath "$INSTDIR\ui\widget"
    File /nonfatal "ui\widget\fuse.font"
 
    ; create the uninstaller
    writeUninstaller "$INSTDIR\uninstall.exe"

    ; Write the uninstall keys for Windows
    WriteRegStr HKLM "${HKLM_REG_KEY}" "DisplayName" "${DISPLAY_NAME}"
    WriteRegStr HKLM "${HKLM_REG_KEY}" "DisplayVersion" "${FUSE_VERSION}"
    WriteRegStr HKLM "${HKLM_REG_KEY}" "HelpLink" "http://fuse-emulator.sourceforge.net/"
    WriteRegStr HKLM "${HKLM_REG_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegDWORD HKLM "${HKLM_REG_KEY}" "NoModify" 1
    WriteRegDWORD HKLM "${HKLM_REG_KEY}" "NoRepair" 1

sectionEnd

;--------------------------------
; Create shortcuts

section "Start Menu and Desktop links" SecShortcuts

    DetailPrint "Creating Shortcuts..."
    CreateDirectory "$SMPROGRAMS\Fuse"
    CreateShortCut "$SMPROGRAMS\Fuse\Fuse.lnk" "$INSTDIR\fuse.exe"
    CreateShortCut "$SMPROGRAMS\Fuse\Manual.lnk" "$INSTDIR\fuse.html"
    CreateShortCut "$SMPROGRAMS\Fuse\Readme.lnk" "$INSTDIR\README.txt"
    CreateShortCut "$SMPROGRAMS\Fuse\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    CreateShortCut "$DESKTOP\Fuse.lnk" "$INSTDIR\fuse.exe"

sectionEnd

;--------------------------------
; Register common file extensions

SectionGroup /e "Register File Extensions" SecFileExt
  ${NewSecExtension} ".pzx" "PZX"
  ${NewSecExtension} ".rzx" "RZX"
  ${NewSecExtension} ".sna" "SNA"
  ${NewSecExtension} ".szx" "SZX"
  ${NewSecExtension} ".tap" "TAP"
  ${NewSecExtension} ".tzx" "TZX"
  ${NewSecExtension} ".z80" "Z80"
SectionGroupEnd

Section "-Register Application"
  WriteRegStr HKLM "Software\Classes\${PROG_ID}\shell" "" "open"
  WriteRegStr HKLM "Software\Classes\${PROG_ID}\DefaultIcon" "" "$INSTDIR\fuse.exe,0"
  WriteRegStr HKLM "Software\Classes\${PROG_ID}\shell\open\command" "" '"$INSTDIR\fuse.exe" "%1"'
  WriteRegStr HKLM "Software\Classes\Applications\fuse.exe" "NoOpenWith" ""

  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v (0x08000000, 0, 0, 0)'
SectionEnd

Function .onInit
  ; Select extensions not associated with other applications
  ${SelectUnregisteredExt} ".pzx" ${SEC_PZX}
  ${SelectUnregisteredExt} ".rzx" ${SEC_RZX}
  ${SelectUnregisteredExt} ".sna" ${SEC_SNA}
  ${SelectUnregisteredExt} ".szx" ${SEC_SZX}
  ${SelectUnregisteredExt} ".tap" ${SEC_TAP}
  ${SelectUnregisteredExt} ".tzx" ${SEC_TZX}
  ${SelectUnregisteredExt} ".z80" ${SEC_Z80}
FunctionEnd

;--------------------------------
; uninstaller section start

section "uninstall"

    ; Unregister file extensions association (if owned)
    DetailPrint "Deleting Registry Keys..."
    ${unregisterExtension} ".pzx"
    ${unregisterExtension} ".rzx"
    ${unregisterExtension} ".sna"
    ${unregisterExtension} ".szx"
    ${unregisterExtension} ".tap"
    ${unregisterExtension} ".tzx"
    ${unregisterExtension} ".z80"

    ; Unregister Application
    DeleteRegKey HKLM "Software\Classes\${PROG_ID}"
    DeleteRegKey HKLM "Software\Classes\Applications\fuse.exe"

    System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v (0x08000000, 0, 0, 0)'
	
    ; Delete the links
    DetailPrint "Deleting Shortcuts..."
    Delete "$SMPROGRAMS\Fuse\Fuse.lnk"
    Delete "$SMPROGRAMS\Fuse\Manual.lnk"
    Delete "$SMPROGRAMS\Fuse\Readme.lnk"
    Delete "$SMPROGRAMS\Fuse\Uninstall.lnk"
    RMDir  "$SMPROGRAMS\Fuse"
    Delete "$DESKTOP\Fuse.lnk"

    ; Installation files
    DetailPrint "Deleting Files..."
    Delete "$INSTDIR\lib\*"
    RMDir  "$INSTDIR\lib"
    Delete "$INSTDIR\roms\*"
    RMDir  "$INSTDIR\roms"
    Delete "$INSTDIR\AUTHORS.txt"
    Delete "$INSTDIR\ChangeLog.txt"
    Delete "$INSTDIR\COPYING.txt"
    Delete "$INSTDIR\fuse.exe"
    Delete "$INSTDIR\fuse.html"
    Delete "$INSTDIR\manual*.png"
    Delete "$INSTDIR\README.txt"
    Delete "$INSTDIR\README-win32.txt"
    Delete "$INSTDIR\*.dll"
    RMDir "$INSTDIR"

    ; Delete the uninstaller and remove the uninstall keys for Windows
    DetailPrint "Deleting Uninstaller..."
    Delete "$INSTDIR\uninstall.exe"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Fuse"

sectionEnd

Function un.DeleteConfigFile
    Delete "$PROFILE\fuse.cfg"
FunctionEnd

;--------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "The core files required to use Fuse (program, libraries, ROMs, etc.)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecShortcuts} "Adds icons to your start menu and your desktop for easy access"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecFileExt} "Register common file extensions with Fuse: pzx, rzx, sna, szx, tap, tzx and z80"
!insertmacro MUI_FUNCTION_DESCRIPTION_END
