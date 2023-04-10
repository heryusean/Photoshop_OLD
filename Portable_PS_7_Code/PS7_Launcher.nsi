;Photoshop 7.0 Launcher

;Copyright (C) 
;2006 Jonathan Durant 

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA02110-1301, USA.

;---Definitions----

!define SNAME "Portable_PS_7"
!define SETDIR "$EXEDIR\Settings"
!define PROGDIR "$EXEDIR\Photoshop"

;----Includes----

!include "Registry.nsh"

;-----Runtime switches----
CRCCheck on
AutoCloseWindow True
SilentInstall silent
WindowIcon off
XPSTYLE on 

;-----Set basic information-----

Name "Portable Photoshop 7.0"
Icon "${SNAME}.ico "
Caption "Portable Photoshop 7.0 Launcher -  Version 0.1"
OutFile "${SNAME}.exe"

;-----Variables----

Var REGINFO
Var REGFILE
Var REGKEY
Var APPNAME
Var DEVNAME
Var EXECUTABLE

;-----Version Information------

LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"

VIProductVersion "0.1.0.0"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "Portable Photoshop 7.0 Launcher"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "© Jonathan Durant 2006"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Allows portability of Adobe Photoshop 7.0."
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "0.1"

;Registry Search Function
Function "RegSearch"
	Pop $R0
	${registry::Open} "HKEY_CURRENT_USER" "/K=1 /V=0 /S=0 /B=1 /N='$R0'" $0
	StrCmp $0 -1 0 find
	
	find:
		${registry::Find} $1 $2 $3 $4
		StrCmp $4 '' return
		StrCmp $4 'REG_KEY' 0 return
		StrCpy $REGKEY "HKCU\$1\$2\$3"
		StrCpy $R1 $REGKEY 
		Push $R1
		${registry::Close}
		${registry::Unload}
		Return
			return:
				${registry::Close}
				${registry::Unload}
				StrCpy $R1 ""
				Push $R1
				Return
FunctionEnd

Section "Main"

;Read Program settings
IfFileExists "${SETDIR}\${SNAME}.ini" INIExists NoINI
	INIExists:
		ReadINIStr $DEVNAME "${SETDIR}\${SNAME}.ini" "PROGSETTINGS" "DEVNAME"
		ReadINIStr $APPNAME "${SETDIR}\${SNAME}.ini" "PROGSETTINGS" "APPNAME"
		ReadINIStr $EXECUTABLE "${SETDIR}\${SNAME}.ini" "PROGSETTINGS" "EXECUTABLE"
		ReadINIStr $REGFILE "${SETDIR}\${SNAME}.ini" "REGSETTINGS" "REGFILE"
		goto iniCheck
	NoINI:
		Messagebox MB_OK "           No ${SNAME}.ini file found.$\nPlease see readme.txt for more information."
		goto end

;Check for problems with INI
iniCheck:
	StrCmp $EXECUTABLE "" empty notEmpty
		empty:
			Messagebox MB_OK "        No Application Executable set in the ${SNAME}.ini file.$\nPlease fill in this information for this program to work correctly."
			Goto End
		notEmpty:
			Goto regInfoCheck

;Check for Registration information file
regInfoCheck:
	IfFileExists "${SETDIR}\RegInfo.reg" setRegInfo regInfoError
		setRegInfo:
			StrCpy "$REGINFO" "${SETDIR}\RegInfo.reg"
			Goto restoreReg
		regInfoError:
			Messagebox MB_OK "Photoshop 7.0 needs registration information$\nto run correctly, unfortunately no registration$\ninformation was found.Please follow the$\n'Registration Info Instructions'in the readme.txt to$\nfix this problem."
			Goto End
			
;restore reg settings					
restoreReg:
	StrCmp $REGFILE "" restoreAlt Restore
	Restore:
		${registry::RestoreKey} "$REGINFO" $R0
		${registry::RestoreKey} "$REGFILE" $R0
		goto ExecProgram
	restoreAlt:
		${registry::RestoreKey} "$REGINFO" $R0
		goto ExecProgram

; Start program
ExecProgram:
	ExecWait "${PROGDIR}\$EXECUTABLE.exe"
	goto checkRegDevName

;Find Registry Key
checkRegDevName:
	StrCpy $R0 $DEVNAME
	Push $R0
	Call RegSearch
	Pop $R1
	StrCmp $R1 "" checkRegAppName next
	next:
	StrCpy $REGKEY $R1
	goto saveRegKey
checkRegAppName:
	StrCpy $R0 $APPNAME
	Push $R0
	Call RegSearch
	Pop $R1
	StrCmp $R1 "" checkExecName next2
	next2:
	StrCpy $REGKEY $R1
	goto saveRegKey
checkExecName:
	StrCpy $R0 $EXECUTABLE
	Push $R0
	Call RegSearch
	Pop $R1
	StrCmp $R1 "" useManRegKey next3
	next3:
	StrCpy $REGKEY $R1
	goto saveRegKey
useManRegKey:
	ReadINIStr $REGKEY "${SETDIR}\${SNAME}.ini" "REGSETTINGS" "MANREGKEY"
	goto saveRegKey

;Check search resutls and export registry key	
saveRegKey:
StrCmp $REGKEY "" error save

	error:
		Messagebox MB_OK "Unfortunately no registry entry could be found within the search criteria.$\nPlease read the 'Finding Registry Key Info' section in the readme.txt file."
		${Registry::DeleteKey} "HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\Photoshop" $R0
		goto end

	save:
		StrCmp $REGFILE "" create overwrite
		create:
			${registry::SaveKey} "$REGKEY" "${SETDIR}\Settings.reg" "/G=1" $R0
			${registry::DeleteKey} "$REGKEY" $R0
			${registry::DeleteKey} "HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\Photoshop" $R0
			goto saveINIdata
		overwrite:
			Delete $EXEDIR\Settings\$REGFILE
			${registry::SaveKey} "$REGKEY" "$REGFILE" "/G=1" $R0
			${registry::DeleteKey} "$REGKEY" $R0
			${registry::DeleteKey} "HKEY_LOCAL_MACHINE\SOFTWARE\Adobe\Photoshop" $R0
			goto saveINIdata
		
	saveINIdata:
		WriteINIStr "${SETDIR}\${SNAME}.ini" "REGSETTINGS" "REGFILE" "${SETDIR}\Settings.reg"
		WriteINIStr "${SETDIR}\${SNAME}.ini" "REGSETTINGS" "REGISTRATIONINFO" $REGINFO
		WriteINIStr "${SETDIR}\${SNAME}.ini" "REGSETTINGS" "MANREGKEY" $REGKEY
	goto End

End:
SectionEnd