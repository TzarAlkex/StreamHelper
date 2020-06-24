#include-once
; ===============================================================================================================================
; <IE_EmbeddedVersioning.au3>
;
; UDF For getting and setting Internet Explorer Embedded Version Emulation mode (for Embedded IE Controls).
; Embedded IE Controls default to version 7 IE Compatibility-Mode (for version 7+), which lacks most HTML5 features,
; so it is necessary to manually tweak the version supported to enable support for new HTML5 features,
; such as HTML5 Canvas
;
; IMPORTANT: Elevated Privileges are required if modifying the HKLM branch of the Registry
;
; Functions:
; 	_IE_EmbeddedGetVersion()			; Gets version of IE Embeddable Control (from ieframe.dll or Registry)
;	_IE_EmbeddedGetBrowserEmulation()	; Gets Browser Emulation Version for given Executable (or 0 if not found)
;	_IE_EmbeddedSetBrowserEmulation()	; Sets Browser Emulation Version. NOTE: HKLM branch REQUIRES ELEVATED PRIVILEGES!
;	_IE_EmbeddedRemoveBrowserEmulation(); Removes Browser Emulation data for executable from Registry
; INTERNAL-ONLY:
;	__IE_FEATURE_BROWSER_EMULATION_CommonOps()	; used by [Get/Set]BrowserEmulation functions
;
; Resources:
;
; -Versions-
; "How to get the IE version number from the Windows registry?" : jrun1 answer
;  @ http://stackoverflow.com/a/20132818
; "Information about Internet Explorer versions" : "How to determine the version of Internet Explorer for Windows"
;  @ http://support.microsoft.com/kb/969393
; Old: "Determine the version of Internet Explorer installed on a local machine"
;  @ http://www.codeproject.com/Articles/1583/Determine-the-version-of-Internet-Explorer-install
;
; -IE Embedded Control-
; "Web Browser Control - Specifying the IE Version":
;  @ http://weblog.west-wind.com/posts/2011/May/21/Web-Browser-Control-Specifying-the-IE-Version
; "_IECreateEmbedded embed old ie version (7 when 9 is installed) Please help thanks!"
;  @ http://www.autoitscript.com/forum/topic/144996-iecreateembedded-embed-old-ie-version-7-when-9-is-installed-please-help-thanks/
;
; See also:
; <IE_EmbeddedEmulationExample.au3>	; Example use, using Canvas
;
; Author: Ascend4nt
; ===============================================================================================================================
#include <WinAPIFiles.au3>	; GetBinaryType

; ===================================================================================================================
; Func _IE_EmbeddedGetVersion()
;
; Returns the current version of the Embedded IE Control (found in system file "ieframe.dll" for IE 7+)
;
; Returns:
;  Success: Version #, @extended = major version #, @error = 0
;  Failure: 0, @error set:
;   @error = 2 = FileGetVersion AND RegRead error. @extended = RegRead() error
;
; Author: Ascend4nt
; ===================================================================================================================

Func _IE_EmbeddedGetVersion()
	; Old versions (6 in XP and lower) use "shdocvw.dll". File still included in System32, but last is 6.xx
	; IE 7 and up use "ieframe.dll" on O/S's from XP on
	Local $sIEVer = FileGetVersion(@SystemDir & "\ieframe.dll")	; GetFileVersionInfo()
	If Not @error Then Return SetExtended(Int($sIEVer), $sIEVer)

	; @error condition... either issue reading version, or pre-7 IE (in which "shdocvw.dll" has the version #)
	; Alternatively, registry should have the version as well:
	Local Const $IE_REG_BRANCH = "HKLM\SOFTWARE\Microsoft\Internet Explorer"

	; Versions 7 through 9:
	$sIEVer = RegRead($IE_REG_BRANCH, "Version")
	If @error Then Return SetError(2, @error, 0)
	;; Versions 10+:
	;; ("Version" will always start with "9", as in "9.xx.xxxx.xxxxx" for
	;;  backwards-compatibility with software that only recognize 1-digit major versions)
	;; IE 10 reads Version as 9.10.9200.16384, and IE 11 as 9.11.9600.17207 (minor version reflects major here)
	;; See "Information about Internet Explorer versions" : "How to determine the version of Internet Explorer for Windows"
	;;  @ http://support.microsoft.com/kb/969393
	If StringLeft($sIEVer, 2) = "9." Then
		Local $sIESvcVer = RegRead($IE_REG_BRANCH, "svcVersion")
		If Not @error And StringLeft($sIESvcVer, 2) <> "9." Then $sIEVer = $sIESvcVer
	EndIf
	Return SetExtended(Int($sIEVer), $sIEVer)
EndFunc


; ===================================================================================================================
; Func _IE_EmbeddedGetBrowserEmulation($bHKLMBranch = False, $sExeName = @AutoItExe)
;
; Gets the FEATURE_BROWSER_EMULATION value for the given Executable.
; If no value is found, 0 will be returned with @error set to 2 and
;  @extended set to 1 (for branch not found), or
;  @extended set to -1 (for value not found)
;
; Parameters:
;  $bHKLMBranch = If False (default), reads the HKCU branch of the Registry
;                 If True, reads HKLM branch
;  $sExeName = Full path to executable, or local name if in curent working directory
;              Note that this is reduced to JUST the filename & extension, as that is what is
;              entered in the Registry
;
; Returns:
;  Success: non-zero value indicating value in the registry
;  Failure: 0 with @error set as following:
;   @error = 1    = invalid parameter(s)
;   @error = 6432 = Executable is 64-bit, but O/S is 32-bit (can't even run the executable)
;   @error = 2    = Error reading from Registry, @extended = error returned from RegRead()
;                   NOTE: @extended = -1 indicates value-not-found.
;                   Also if branch not found, @extended = 1
;
; Author: Ascend4nt
; ===================================================================================================================

Func _IE_EmbeddedGetBrowserEmulation($bHKLMBranch = False, $sExeName = @AutoItExe)
	Local $aData = __IE_FEATURE_BROWSER_EMULATION_CommonOps($sExeName, $bHKLMBranch)
	If @error Then Return SetError(@error, @extended, 0)
	; [0] = Registry Key Branch, [1] = file.exe [also valuename], [2] = IsExeX64
	Local $nRegVal = RegRead($aData[0], $aData[1])
	If @error Then Return SetError(2, @error, 0)

;~ 	ConsoleWrite("'" & $aData[1] & "' has FEATURE_BROWSER_EMULATION set to " & $nRegVal & " (64-bit? = " & $aData[2] & ")" & @CRLF)
	Return $nRegVal
EndFunc


; ===================================================================================================================
; Func _IE_EmbeddedSetBrowserEmulation($nIEVersion = -1, $bIgnoreDOCTYPE = True, $bHKLMBranch = False, $sExeName = @AutoItExe)
;
; Sets the Browser Emulation mode for Embedded IE Controls (which uses ieframe.dll)
; By default, embedded IE Controls run in IE 7 compatibility mode, which causes most HTML5 features to fail
;
; The workaround for this problem is to insert a special value for the executable into the Registry,
; which will allow Embedded IE Controls to run as later IE versions
;
; NOTE: if $bHKLMBranch is True, elevated privileges are required to modify that branch in the Registry!
;
; Parameters:
;  $nIEVersion = Base version of Internet Explorer, OR extended dot version (11.0.9600.17207)
;                Int() is used to reduce the version to an integer
;                -1 (default) gets current installed IE control version via _IE_EmbeddedGetVersion()
;                Valid IE versions: 7, 8, 9, 10, 11. Versions 12+ are supported but
;                the IgnoreDOCTYPE value *may* be wrong if they change the numbering scheme
;
;  $bIgnoreDOCTYPE = If True (default), the "!DOCTYPE" directive on webpages is ignored
;                    If False or 0, the "!DOCTYPE" directive affects how IE interprets the page
;                    and can cause IE to go into 'quirks' mode
;                    Note that if $nIEVersion is 7, then "!DOCTYPE" always affects IE interpretation
;  $bHKLMBranch = If False (default), uses the HKCU branch of the Registry
;                 If True, uses HKLM branch (and requires elevation!)
;  $sExeName = Full path to executable, or local name if in curent working directory
;              Note that this is reduced to JUST the filename & extension, as that is what is
;              entered in the Registry
;
; Returns:
;  Success: non-zero value indicating value written to the registry
;  Failure: 0 with @error set as following:
;   @error = 1    = invalid parameter(s)
;   @error = 6432 = Executable is 64-bit, but O/S is 32-bit (can't even run the executable)
;   @error = 2    = Error writing to Registry, @extended = error returned from RegWrite()
;   @error = -1   = Not running as Administrator, thus can not change/write to Registry
;                   NOTE that if the Registry key is already set correctly, the write is skipped
;                   and the function should return success
;
; Author: Ascend4nt
; ===================================================================================================================

Func _IE_EmbeddedSetBrowserEmulation($nIEVersion = -1, $bIgnoreDOCTYPE = True, $bHKLMBranch = False, $sExeName = @AutoItExe)
;~ 	ConsoleWrite("_IE_SetEmbeddedBrowserEmulation(): $nIEVersion: " & $nIEVersion & ", $bIgnoreDOCTYPE = " & $bIgnoreDOCTYPE & ", $sExe: " & $sExeName & @CRLF)

	; Call common function (same as Get function) to check executable type (32 or 64-bit), cut filename.ext out,
	; and determine appropriate registry branch to write to
	Local $aData = __IE_FEATURE_BROWSER_EMULATION_CommonOps($sExeName, $bHKLMBranch)
	If @error Then Return SetError(@error, @extended, 0)
	; [0] = Registry Key Branch, [1] = file.exe [also valuename], [2] = IsExeX64
	Local $sRegBranch = $aData[0] ;, $bExeIsX64 = $aData[2]
	$sExeName = $aData[1]

	; Default? Use greatest IE version available as read from ieframe.dll or the Registry:
	If $nIEVersion < 0 Then $nIEVersion = _IE_EmbeddedGetVersion()

	; FEATURE_BROWSER_EMULATION Registry value determination

	; Registry Key uses values in thousands (8 = 8000, 9 = 9000)
	Local $nIEBrowseEmuVal = Int($nIEVersion) * 1000
	; !DOCTYPE directive handling: If we are to ignore the directive, we need to determine value based on browser version,
	; as older versions used specific values, while newer browsers (10+) just add 1 to the base value
	Switch $nIEBrowseEmuVal
		Case 7000
			;$bIgnoreDOCTYPE has no meaning for IE7 mode
		Case 8000
			If $bIgnoreDOCTYPE Then $nIEBrowseEmuVal = 8888
		Case 9000
			If $bIgnoreDOCTYPE Then $nIEBrowseEmuVal = 9999
		Case 10000, 11000
			If $bIgnoreDOCTYPE Then $nIEBrowseEmuVal += 1
		Case Else
			If $nIEBrowseEmuVal < 7000 Then Return SetError(1, 0, 0)
			; Otherwise we'll assume FUTURE IE Version that might behave like 10 and 11:
			If $bIgnoreDOCTYPE Then $nIEBrowseEmuVal += 1
	EndSwitch

;~ 	ConsoleWrite("FEATURE_BROWSER_EMULATION value = " & $nIEBrowseEmuVal & @CRLF)

	; Now Get/Set the Registry Key

	Local $nRegVal = RegRead($sRegBranch, $sExeName)
	If @error Or $nRegVal <> $nIEBrowseEmuVal Then
;~ 		ConsoleWrite("_IE_EmbeddedSetBrowserEmulation(): Key read value = " & $nRegVal & ", @error = " & @error & @CRLF)
		If Not $bHKLMBranch Or IsAdmin() Then
			RegWrite($sRegBranch, $sExeName, "REG_DWORD", $nIEBrowseEmuVal)
			If @error Then Return SetError(2, @error, 0)
		Else
;~ 			ConsoleWrite("Not Admin! Can't write to HKLM branch!" & @CRLF)
			Return SetError(-1, $nRegVal, 0)
		EndIf
	EndIf
	; Success if got here
;~ 	ConsoleWrite("Operation Success! '" & $sExeName & "' now has FEATURE_BROWSER_EMULATION set to " & $nIEBrowseEmuVal & " (64-bit? = " & $bExeIsX64 & ")" & @CRLF)
	Return $nIEBrowseEmuVal
EndFunc


; ===================================================================================================================
; Func _IE_EmbeddedRemoveBrowserEmulation($bHKLMBranch = False, $sExeName = @AutoItExe)
;
; Removes a valuename for a given executable from the Registry.
; This effectively causes any further runs of the executable to use the old IE 7 legacy emulation,
; unless it is set once again.
;
; Parameters:
;  $bHKLMBranch = If False (default), deletes the value from the HKCU branch of the Registry
;                 If True, deletes the value from the HKLM branch
;  $sExeName = Either just the executable name ('autoit3.exe') or a full path to executable
;              The full path is preferred in the case of HKLM branch, as this can more easily determine
;              the branch of the registry to look at - otherwise, the 32-bit branch is searched 1st,
;              followed by 64-bit branch.
;              Note that in both cases (full path/exe name), the string is reduced to JUST the
;              filename & extension, as that's what the valuename must be in the Registry
;
; Returns:
;  Success: 1, with optional @error = -1 if key/value didn't exist (can be considered 'success')
;  Failure: 0 with @error set as following:
;   @error = 1    = invalid parameter(s)
;   @error = 6432 = Executable is 64-bit, but O/S is 32-bit (can't even run the executable)
;   @error = 2    = Error using RegDelete(), @extended = error returned from RegDelete()
;                   Also if branch not found, @extended = 1
;
; Author: Ascend4nt
; ===================================================================================================================

Func _IE_EmbeddedRemoveBrowserEmulation($bHKLMBranch = False, $sExeName = @AutoItExe)
	Local $aData, $nRet, $nExeBitness

	If $bHKLMBranch And Not IsAdmin() Then
;~ 		ConsoleWrite("Not Admin! Can't modify HKLM branch!" & @CRLF)
		Return SetError(-1, 0, 0)
	EndIf

	; We may be deleting a valuename for an exe that doesn't exist..
	If FileExists($sExeName) Then
		$nExeBitness = 0
	Else
		$nExeBitness = 32
	EndIf

	$aData = __IE_FEATURE_BROWSER_EMULATION_CommonOps($sExeName, $bHKLMBranch, $nExeBitness)
	If @error Then Return SetError(@error, @extended, 0)

;~ 	ConsoleWrite("_IE_EmbeddedRemoveBrowserEmulation: Reg Branch: '" & $aData[0] & "' : valuename of '" & $aData[1] & "'" & @CRLF)

	; [0] = Registry Key Branch, [1] = file.exe [also valuename], [2] = IsExeX64
	$nRet = RegDelete($aData[0], $aData[1])

	; Return of 0 = key/value doesn't exist, @error = 1 means unable to open key..
	; We only need to try again for HKLM branch when the architecture is 64-bit (otherwise HKCU is universal)
	If $nRet = 0 And $bHKLMBranch And $nExeBitness = 32 And @OSArch = "X64" Then
;~ 		ConsoleWrite("32-bit HKLM value not found - trying 64-bit HKLM branch" & @CRLF)
		; (No error return when we specify bitness)
		$aData = __IE_FEATURE_BROWSER_EMULATION_CommonOps($sExeName, $bHKLMBranch, 64)
		$nRet = RegDelete($aData[0], $aData[1])
	EndIf
	If @error Then Return SetError(2, @error, 0)

;~ 	ConsoleWrite("'" & $aData[0] & "' : valuename of '" & $aData[1] & "' RegDelete returned: " & $nRet & ", (64-bit? = " & $aData[2] & ")" & @CRLF)
	If $nRet = 0 Then Return SetError(-1, 0, 1)
	Return $nRet
EndFunc



#Region IE_EMBEDDED_VERSION_INTERNAL
; ===================================================================================================================
; Func __IE_FEATURE_BROWSER_EMULATION_CommonOps($sExeName, $bHKLMBranch, $nExeBitness = 0)
;
; *Internal* Function used by _IE_[Get/Set]EmbeddedBrowserEmulation() functions
; Checks executable type (32 or 64-bit), trims filename.ext out of path, and determines correct Registry key
;
; $nExeBitness = 0 (default) - detects bitness from Executable. Otherwise, either 32 or 64
;
; Author: Ascend4nt
; ===================================================================================================================

Func __IE_FEATURE_BROWSER_EMULATION_CommonOps($sExeName, $bHKLMBranch, $nExeBitness = 0)
	Local $bExeIsX64

	If $nExeBitness Then
		$bExeIsX64 = ($nExeBitness = 64)
	Else
		; Note: This call isn't necessary for HKCU branch, but it at least lets us verify
		; that the file exists and that it is an executable file:
		If Not _WinAPI_GetBinaryType($sExeName) Then Return SetError(1, 0, 0)

		; See if executable is 64-bit app (relies on @extended from GetBinaryType call above)
		Switch @extended	; Binary Type
			Case $SCS_32BIT_BINARY	; 0
				$bExeIsX64 = 0
			Case $SCS_64BIT_BINARY	; 6
				$bExeIsX64 = 1
			Case Else
;~ 	 			ConsoleWrite("Binary Type invalid for Win32, Type = " & @extended & @CRLF)
				Return SetError(1, 0, 0)
		EndSwitch
	EndIf

	; Check that O/S is 64-bit if we have a 64-bit Exe
	If $bExeIsX64 And @OSArch <> "X64" Then
;~ 		ConsoleWrite("64-bit executable requested, but O/S is 32-bit!" & @CRLF)
		Return SetError(6432, 0, 0)
	EndIf

	; Remove path from exe string (1st replace '/'s with '\'s)
	Local $nPos = StringInStr(StringReplace($sExeName, '/', '\'), '\', 2, -1)
	If $nPos Then
		$sExeName = StringMid($sExeName, $nPos + 1)
		If $sExeName = "" Then Return SetError(1, 0, 0)
	EndIf

	; 2 Different branches depending on 32-bit or 64-bit executable type
	Local Const $IE_FBE_BRANCH_SUFFIX = "Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"

	Local $sRegBranch

	If Not $bHKLMBranch Then
		; With the HKCU branch, 32 and 64-bitness doesn't matter
		$sRegBranch = "HKCU\Software\" & $IE_FBE_BRANCH_SUFFIX
	Else
		If $bExeIsX64 Then
			; Check for O/S Architecture done above
			; If @OSArch <> "X64" Then Return SetError(1, 0, 0)

			; HKLM64 works whether run from 32 or 64-bit mode [otherwise just use HKLM in 64-bit mode]
			$sRegBranch = "HKLM64\SOFTWARE\" & $IE_FBE_BRANCH_SUFFIX
		Else	; Not $bExeIsX64	; 32-bit EXE

			; Local Const $IE_FBE_32BIT_BRANCH = "HKLM\SOFTWARE\" & ( (@AutoItX64) ? "Wow6432Node\" : "") & $IE_FBE_BRANCH_SUFFIX
			$sRegBranch = "HKLM\SOFTWARE\"
			; Wow6432Note must be used if run in 64-bit mode
			If @AutoItX64 Then $sRegBranch &= "Wow6432Node\"
			$sRegBranch &= $IE_FBE_BRANCH_SUFFIX
		EndIf
	EndIf

	Local $aRet[3] = [$sRegBranch, $sExeName, $bExeIsX64]
	Return $aRet
EndFunc
#EndRegion IE_EMBEDDED_VERSION_INTERNAL
