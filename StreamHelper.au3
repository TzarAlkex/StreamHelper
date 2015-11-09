#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0 (Stable)
 Author:         Alexander Samuelsson AKA AdmiralAlkex

 Script Function:
	Stuff

#ce ----------------------------------------------------------------------------

$sTwitchUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Twitch", "")   ;NAME ON TWITCH
$sHitboxUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Hitbox", "")   ;NAME ON HITBOX
$iRefresh = IniRead(@ScriptDir & "\Settings.ini", "Section", "RefreshMinutes", 10) * 60000   ;HOW MANY TIME UNITS BETWEEN EVERY CHECK FOR NEW STREAMS
$iPrintJSON = IniRead(@ScriptDir & "\Settings.ini", "Section", "PrintJSON", "")   ;PRINT ON JSON
$sCheckForUpdates = IniRead(@ScriptDir & "\Settings.ini", "Section", "CheckForUpdates", "-1")   ;JUST TYPE SOMETHING TO CHECK

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

#include <AutoItConstants.au3>
#include "Json.au3"
#include <Array.au3>
#include <InetConstants.au3>
#include <Date.au3>
#include <GDIPlus.au3>
#include <WinAPIShellEx.au3>
#include <WindowsConstants.au3>
#include <WinAPIDiag.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>

TrayCreateItem("")
Local $idRefresh = TrayCreateItem("Refresh")
TrayItemSetOnEvent( -1, _TrayStuff)

Global $sAppName = "StreamHelper v" & (@Compiled ? FileGetVersion(@ScriptFullPath) : "uncompiled")
If $sCheckForUpdates = "-1" Then
	If MsgBox($MB_YESNO, $sAppName, "Automatically check for updates?") = $IDYES Then
		IniWrite(@ScriptDir & "\Settings.ini", "Section", "CheckForUpdates", "Tomato")
	Else
		IniWrite(@ScriptDir & "\Settings.ini", "Section", "CheckForUpdates", "")
	EndIf
EndIf
$sCheckForUpdates = IniRead(@ScriptDir & "\Settings.ini", "Section", "CheckForUpdates", "-1")

TrayCreateItem("")
Local $idAbout = TrayCreateItem("About")
TrayItemSetOnEvent( -1, _TrayStuff)

Local $idExit = TrayCreateItem("Exit")
TrayItemSetOnEvent( -1, _TrayStuff)

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime, $eOnline, $eService, $eMax
Global Enum $eTwitch, $eHitbox, $eLink

Global $sNew
Global $aStreams[0][$eMax]

Global $iLivestreamerInstalled = StringInStr(EnvGet("path"), "Livestreamer") > 0

Global Const $AUT_WM_NOTIFYICON = $WM_USER + 1 ; Application.h
Global Const $AUT_NOTIFY_ICON_ID = 1 ; Application.h
Global Const $PBT_APMRESUMEAUTOMATIC =  0x12

AutoItWinSetTitle("AutoIt window with hopefully a unique title|Ketchup the second")
Global $TRAY_ICON_GUI = WinGetHandle(AutoItWinGetTitle()) ; Internal AutoIt GUI

_GDIPlus_Startup()

Global $hBitmap, $hImage, $hGraphic
$hBitmap = _WinAPI_CreateSolidBitmap(0, 0xFFFFFF, 16, 16)
$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
$hGraphic = _GDIPlus_ImageGetGraphicsContext($hImage)

_MAIN()

GUICreate("detect WM_POWERBROADCAST")
GUIRegisterMsg($WM_POWERBROADCAST, "_PowerEvents")

While 1
	Sleep(3600000)
WEnd

#Region TWITCH
Func _Twitch()
	ConsoleWrite("Twitching" & @CRLF)
	_ProgressSpecific("T")

	_TwitchGet($sTwitchUsername)

	$iTrayRefresh = True
EndFunc

Func _TwitchGet($sUsername)
	$iLimit = 100
	$iOffset = 0
	$sQuotedUsername = URLEncode($sUsername)
	$sBaseUrl = "https://api.twitch.tv/kraken/users/" & $sQuotedUsername & "/follows/channels"

	While True
		$sUrl = $sBaseUrl & OPTIONS_OFFSET_LIMIT_TWITCH($iOffset, $iLimit)
		$avTemp = FetchItems($sUrl, "follows")
		If UBound($avTemp) = 0 Then ExitLoop

		Local $sOptions
		For $iX = 0 To UBound($avTemp) -1
			$oChannel = Json_ObjGet($avTemp[$iX], "channel")
			$sName = Json_ObjGet($oChannel, "name")
			$sOptions &= $sName & ','
		Next

		$sOptions = StringTrimRight($sOptions, 1)
		$sUrl = 'https://api.twitch.tv/kraken/streams?channel=' & $sOptions & '&limit=' & $iLimit
		$oChannel = FetchItems($sUrl, "streams")

		For $iX = 0 To UBound($oChannel) -1
			$oChannel2 = Json_ObjGet($oChannel[$iX], "channel")
			$sUrl = Json_ObjGet($oChannel2, "url")
			If $sUrl = "" Then $sUrl = "http://www.twitch.tv/" & Json_ObjGet($oChannel2, "name")

			$sDisplayName = Json_ObjGet($oChannel2, "display_name")

			$sStatus = Json_ObjGet($oChannel2, "status")

			$oPreview = Json_ObjGet($oChannel[$iX], "preview")
			$sMedium = Json_ObjGet($oPreview, "medium")

			$sGame = Json_ObjGet($oChannel[$iX], "game")

			$sCreated = Json_ObjGet($oChannel[$iX], "created_at")

			$asSplit = StringSplit($sCreated, "T")
			$asDate = StringSplit($asSplit[1], "-")
			$asTime = StringSplit(StringTrimRight($asSplit[2], 1), ":")

			$tSystemTime = DllStructCreate($tagSYSTEMTIME)
			$tSystemTime.Year = $asDate[1]
			$tSystemTime.Month = $asDate[2]
			$tSystemTime.Day = $asDate[3]
			$tSystemTime.Hour = $asTime[1]
			$tSystemTime.Minute = $asTime[2]
			$tSystemTime.Second = $asTime[3]

			$tFileTime = _Date_Time_SystemTimeToFileTime($tSystemTime)
			$tLocalTime = _Date_Time_FileTimeToLocalFileTime($tFileTime)
			$sTime = _Date_Time_FileTimeToStr($tLocalTime, 1)
			$iHours = _DateDiff("h", $sTime, _NowCalc())
			$iMinutes = _DateDiff("n", $sTime, _NowCalc())
			$iMinutes -= $iHours * 60

			$sTime = StringFormat("%02i:%02i", $iHours, $iMinutes)

			_StreamSet($sDisplayName, $sUrl, $sMedium, $sGame, $sCreated, $sTime, $sStatus, $eTwitch)
		Next

		If UBound($oChannel) <= 100 Then ExitLoop

		$iOffset += $iLimit
	WEnd
	Return "Potato on a Stick"
EndFunc

Func OPTIONS_OFFSET_LIMIT_TWITCH($iOffset, $iLimit)
	Return '?offset=' & $iOffset & '&limit=' & $iLimit
EndFunc
#EndRegion TWITCH

#Region HITBOX
Func _Hitbox()
	ConsoleWrite("Hitboxing" & @CRLF)
	_ProgressSpecific("H")

	_HitboxGet($sHitboxUsername)

	$iTrayRefresh = True
EndFunc

Func _HitboxGet($sUsername)
	$iLimit = 100
	$iOffset = 0
	Static Local $iUserID = ""

	If $iUserID = "" Then
		$sQuotedUsername = URLEncode($sUsername)

		$sUserUrl = "https://api.hitbox.tv/user/" & $sQuotedUsername
		FetchItems($sUserUrl, "", "user_id")
		$iUserID = @extended
		If $iUserID = "" Then Return
	EndIf

	$sUrl = "https://api.hitbox.tv/media/live/list?follower_id=" & $iUserID
	$oLivestream = FetchItems($sUrl, "livestream")
	If UBound($oLivestream) = 0 Then Return

	For $iX = 0 To UBound($oLivestream) -1
		$oChannel = Json_ObjGet($oLivestream[$iX], "channel")
		$sUrl = Json_ObjGet($oChannel, "channel_link")

		$sDisplayName = Json_ObjGet($oLivestream[$iX], "media_display_name")

		$sStatus = Json_ObjGet($oLivestream[$iX], "media_status")

		$sThumbnail = Json_ObjGet($oLivestream[$iX], "media_thumbnail")

		$sGame = Json_ObjGet($oLivestream[$iX], "category_name")

		$sCreated = Json_ObjGet($oLivestream[$iX], "media_live_since")

		$asSplit = StringSplit($sCreated, " ")
		$asDate = StringSplit($asSplit[1], "-")
		$asTime = StringSplit($asSplit[2], ":")

		$tSystemTime = DllStructCreate($tagSYSTEMTIME)
		$tSystemTime.Year = $asDate[1]
		$tSystemTime.Month = $asDate[2]
		$tSystemTime.Day = $asDate[3]
		$tSystemTime.Hour = $asTime[1]
		$tSystemTime.Minute = $asTime[2]
		$tSystemTime.Second = $asTime[3]

		$tFileTime = _Date_Time_SystemTimeToFileTime($tSystemTime)
		$tLocalTime = _Date_Time_FileTimeToLocalFileTime($tFileTime)
		$sTime = _Date_Time_FileTimeToStr($tLocalTime, 1)
		$iHours = _DateDiff("h", $sTime, _NowCalc())
		$iMinutes = _DateDiff("n", $sTime, _NowCalc())
		$iMinutes -= $iHours * 60

		$sTime = StringFormat("%02i:%02i", $iHours, $iMinutes)

		_StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $eHitbox)
	Next

	Return "Potato on a Stick"
EndFunc

Func OPTIONS_OFFSET_LIMIT_HITBOX($iOffset, $iLimit)
	Return '&offset=' & $iOffset & '&limit=' & $iLimit
EndFunc
#EndRegion

#Region COMMON
Func FetchItems($sUrl, $sKey, $sExtendedKey = Null)
	Local $sRetExtended

	$oJSON = getJson($sUrl)

	If IsObj($oJSON) = False Then Return ""

	If IsString($sExtendedKey) Then
		$sRetExtended = Json_ObjGet($oJSON, $sExtendedKey)
	EndIf

	$aFollows = Json_ObjGet($oJSON, $sKey)
	If UBound($aFollows) > 0 Then
		Return SetExtended($sRetExtended, $aFollows)
	Else
		Return SetExtended($sRetExtended, "")
	EndIf
EndFunc

Func getJson($sUrl)
	$dJsonString = InetRead($sUrl, $INET_FORCERELOAD)

	If $iPrintJSON Then ConsoleWrite(BinaryToString($dJsonString) & @CRLF)

	$oJSON = Json_Decode(BinaryToString($dJsonString))
	Return $oJSON
EndFunc

;From https://www.autoitscript.com/forum/topic/95850-url-encoding/?do=findComment&comment=689045
Func URLEncode($urlText)
	$url = ""
	For $i = 1 To StringLen($urlText)
		$acode = Asc(StringMid($urlText, $i, 1))
		Select
			Case ($acode >= 48 And $acode <= 57) Or _
					($acode >= 65 And $acode <= 90) Or _
					($acode >= 97 And $acode <= 122)
				$url = $url & StringMid($urlText, $i, 1)
			Case $acode = 32
				$url = $url & "+"
			Case Else
				$url = $url & "%" & Hex($acode, 2)
		EndSelect
	Next
	Return $url
EndFunc   ;==>URLEncode
#EndRegion

#Region GUI
Func _TrayRefresh()
	_ArraySort($aStreams, 1)

	For $iX = 0 To UBound($aStreams) -1
		If $aStreams[$iX][$eOnline] = True Then
			If $aStreams[$iX][$eTrayId] = 0 Then
				If $aStreams[$iX][$eGame] <> "" Then
					$aStreams[$iX][$eTrayId] = TrayCreateItem($aStreams[$iX][$eDisplayName] & " | " & $aStreams[$iX][$eGame], -1, 0)
				Else
					$aStreams[$iX][$eTrayId] = TrayCreateItem($aStreams[$iX][$eDisplayName], -1, 0)
				EndIf
				TrayItemSetOnEvent( -1, _TrayStuff)

				$sNew &= $aStreams[$iX][$eDisplayName] & " | " & $aStreams[$iX][$eGame] & @CRLF
			Else
				TrayItemSetText($aStreams[$iX][$eTrayId], $aStreams[$iX][$eDisplayName] & " | " & $aStreams[$iX][$eGame])
			EndIf
			$aStreams[$iX][$eOnline] = False
		Else
			If $aStreams[$iX][$eTrayId] <> 0 And $aStreams[$iX][$eService] <> $eLink Then
				TrayItemDelete($aStreams[$iX][$eTrayId])
				$aStreams[$iX][$eTrayId] = 0
			EndIf
		EndIf
	Next
EndFunc

Func _TrayStuff()
	Switch @TRAY_ID
		Case $idAbout
			Local $asText[] = ["I am unfinished", "Ouch", "Quit poking me!", "Bewbs", "Pizza", "25W lightbulb (broken)", "Estrellas Salt & Vinäger chips är godast", "Vote Pewdiepie for King of Sweden", "Vote Robbaz for King of Sweden", "Vote Anderz for King of Sweden", "I'm sorry trancexx", "Vote Knugen for King of Sweden", '"Is it creepy that I follow you, should I stop doing it?" -Xandy', '"I can''t be expected to perform under pressure!" -jaberwacky', '"The square root of 76 is brown" -One F Jef', "42", '"THERE... ARE... FOUR LIGHTS!" - Picard']
			$iRandom = Random(0, UBound($asText) -1, 1)
			MsgBox(0, @ScriptName, "Add text here" & @CRLF & @CRLF & "Created by Alexander Samuelsson AKA AdmiralAlkex" & @CRLF & @CRLF & "[" & $iRandom +1 & "/" & UBound($asText) & "] " & $asText[$iRandom])
		Case $idRefresh
			_MAIN()
		Case $idExit
			Exit
		Case Else
			Local $sUrl   ;Remove this variable?

			For $iX = 0 To UBound($aStreams) -1
				If $aStreams[$iX][$eTrayId] = @TRAY_ID Then
					$sUrl = $aStreams[$iX][$eUrl]
					ExitLoop
				EndIf
			Next

			If $iLivestreamerInstalled And $aStreams[$iX][$eService] <> $eLink Then
				Run("livestreamer " & $sUrl & " best", "", @SW_HIDE)
			Else
				ShellExecute($sUrl)
			EndIf
	EndSwitch
EndFunc

;Based on https://www.autoitscript.com/forum/topic/115222-set-the-tray-icon-as-a-hicon/
Func _TraySet($sText)
	_GDIPlus_GraphicsClear($hGraphic, 0xFFFFFFFF)

	$hFamily = _GDIPlus_FontFamilyCreate('Arial')
	$hFont = _GDIPlus_FontCreate($hFamily, 9, 1, 2)
	$tLayout = _GDIPlus_RectFCreate(0, 0, 0, 0)
	$hFormat = _GDIPlus_StringFormatCreate()
	$hBrush = _GDIPlus_BrushCreateSolid(0xFF000000)
	$aData = _GDIPlus_GraphicsMeasureString($hGraphic, $sText, $hFont, $tLayout, $hFormat)
	$tLayout = $aData[0]
	DllStructSetData($tLayout, 1, (_GDIPlus_ImageGetWidth($hImage) - DllStructGetData($tLayout, 3)) / 2)
	DllStructSetData($tLayout, 2, (_GDIPlus_ImageGetHeight($hImage) - DllStructGetData($tLayout, 4)) / 2)
	_GDIPlus_GraphicsDrawStringEx($hGraphic, $sText, $hFont, $aData[0], $hFormat, $hBrush)
	_GDIPlus_StringFormatDispose($hFormat)
	_GDIPlus_FontFamilyDispose($hFamily)
	_GDIPlus_FontDispose($hFont)
	_GDIPlus_BrushDispose($hBrush)

	$hIcon = _GDIPlus_HICONCreateFromBitmap($hImage)

	Local $tNOTIFY = DllStructCreate($tagNOTIFYICONDATA)
	$tNOTIFY.Size = DllStructGetSize($tNOTIFY)
	$tNOTIFY.hWnd = $TRAY_ICON_GUI
	$tNOTIFY.ID = $AUT_NOTIFY_ICON_ID
	$tNOTIFY.hIcon = $hIcon
	$tNOTIFY.Flags = BitOR($NIF_ICON, $NIF_MESSAGE)
	$tNOTIFY.CallbackMessage = $AUT_WM_NOTIFYICON

	_WinAPI_ShellNotifyIcon($NIM_MODIFY, $tNOTIFY)
	_WinAPI_DestroyIcon($hIcon)
EndFunc

Func _ProgressSpecific($sText)
	_TraySet($sText)
EndFunc

Func _MAIN()
	AdlibUnRegister(_MAIN)

	Global $sNew = ""
	If $sCheckForUpdates <> "" Then _CheckUpdates()
	If $sTwitchUsername <> "" Then _Twitch()
	If $sHitboxUsername <> "" Then _Hitbox()
	ConsoleWrite("Getters done" & @CRLF)
	_TrayRefresh()
	TraySetIcon()

	If $sNew <> "" Then
		$iSkipped = 0
		While StringLen($sNew) > 240
			$iPos = StringInStr($sNew, @CRLF, $STR_CASESENSE, -1)
			$sNew = StringLeft($sNew, $iPos -1)
			$iSkipped += 1
		WEnd
		If $iSkipped > 0 Then
			$sNew &= @CRLF & "+" & $iSkipped & " more"
		EndIf

		TrayTip("Now streaming", $sNew, 10)
	EndIf

	AdlibRegister(_MAIN, $iRefresh)
EndFunc
#EndRegion GUI

#Region INTENRAL INTERLECT
Func _StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $iService)
	ConsoleWrite("Found streamer: " & $sDisplayName & @CRLF)

	For $iIndex = 0 To UBound($aStreams) -1
		If $aStreams[$iIndex][$eUrl] = $sUrl Then ExitLoop
	Next
	If $iIndex = UBound($aStreams) Then
		ReDim $aStreams[$iIndex +1][$eMax]
	EndIf

	$aStreams[$iIndex][$eDisplayName] = $sDisplayName
	$aStreams[$iIndex][$eUrl] = $sUrl
	$aStreams[$iIndex][$ePreview] = $sThumbnail
	$aStreams[$iIndex][$eGame] = $sGame
	$aStreams[$iIndex][$eCreated] = $sCreated
	$aStreams[$iIndex][$eTime] = $sTime
	$aStreams[$iIndex][$eStatus] = $sStatus
	$aStreams[$iIndex][$eOnline] = True
	$aStreams[$iIndex][$eService] = $iService
EndFunc

Func _PowerEvents($hWnd, $Msg, $wParam, $lParam)
	Switch $wParam
		Case $PBT_APMRESUMEAUTOMATIC
			AdlibUnRegister(_MAIN)
			AdlibRegister(_ComputerResumed)
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>_PowerEvents

Func _ComputerResumed()
	If _WinAPI_IsInternetConnected() Then
		AdlibUnRegister(_ComputerResumed)
		_MAIN()
	EndIf
EndFunc

Func _CheckUpdates()
	ConsoleWrite('"Updateing"' & @CRLF)
	_ProgressSpecific("U")
	$sCheckForUpdates = ""

	Local $dData = InetRead("https://dl.dropboxusercontent.com/u/18344147/SoftwareUpdates/StreamHelper.txt", $INET_FORCERELOAD)
	Local $sData = BinaryToString($dData)
	$aRet = StringSplit($sData, "|")
	If @error Then Return
	If $aRet[0] <> 2 Then Return
	If $aRet[1] <= 1 Then Return   ;Version

	_StreamSet("Update found! Click to open website", "https://github.com/TzarAlkex/StreamHelper/releases", "", "", "", "", "", $eLink)
EndFunc
#EndRegion