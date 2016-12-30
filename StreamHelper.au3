#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Svartnos.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=1.1.0.0
#AutoIt3Wrapper_Res_ProductVersion=1.1.0.0
#AutoIt3Wrapper_Res_Description=StreamHelper
#AutoIt3Wrapper_Res_LegalCopyright=My right shoe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0 (Stable)
 Author:         Alexander Samuelsson AKA AdmiralAlkex

 Script Function:
	Stuff



Activate Twitch support on livestreamer with:
https://github.com/chrippa/livestreamer/issues/1456#issuecomment-247192307

Todo:
*Should probably do the recovery mode thing also when internet disappears and not just when waking the computer
*Add back the quality stuff in the array now that Twitch changed how they allocate transcoding to non-partners?
*Always save quality stuff to array for partners?
*Beep confirmed as annoying.

#ce ----------------------------------------------------------------------------

If (Not @Compiled) Then
	TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
EndIf

$sTwitchUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Twitch", "")   ;NAME ON TWITCH
$sHitboxUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Hitbox", "")   ;NAME ON HITBOX
$iRefresh = IniRead(@ScriptDir & "\Settings.ini", "Section", "RefreshMinutes", 2) * 60000   ;HOW MANY TIME UNITS BETWEEN EVERY CHECK FOR NEW STREAMS
$iPrintJSON = IniRead(@ScriptDir & "\Settings.ini", "Section", "PrintJSON", "")   ;PRINT ON JSON
$sCheckForUpdates = IniRead(@ScriptDir & "\Settings.ini", "Section", "CheckForUpdates", "-1")   ;JUST TYPE SOMETHING TO CHECK

$sFavorites = IniRead(@ScriptDir & "\Settings.ini", "Section", "Favorites", "")
$sIgnore = IniRead(@ScriptDir & "\Settings.ini", "Section", "Ignore", "")
Global $sOldFavorites = $sFavorites
Global $sOldIgnore = $sIgnore

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)
Opt("GUIOnEventMode", 1)

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
#include <WinAPISys.au3>
#include <GuiComboBox.au3>
#include <Misc.au3>

TrayCreateItem("")
Local $idRefresh = TrayCreateItem("Refresh")
TrayItemSetOnEvent( -1, _TrayStuff)

Local $idClipboard = TrayCreateItem("Play from clipboard")
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

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime, $eOnline, $eService, $eQualities, $eMax
Global Enum $eTwitch, $eHitbox, $eLink

Global $sNew
Global $aStreams[0][$eMax]

Global $iLivestreamerInstalled = StringInStr(EnvGet("path"), "Livestreamer") > 0
Global $bBlobFirstRun = True

Global Const $AUT_WM_NOTIFYICON = $WM_USER + 1 ; Application.h
Global Const $AUT_NOTIFY_ICON_ID = 1 ; Application.h
Global Const $PBT_APMRESUMEAUTOMATIC =  0x12

AutoItWinSetTitle("AutoIt window with hopefully a unique title|Ketchup the second")
Global $TRAY_ICON_GUI = WinGetHandle(AutoItWinGetTitle()) ; Internal AutoIt GUI
Global $hGuiClipboard
Global $idLabel, $idQuality, $idPlay
Global $sUrl
Global $avDownloads[1][2]

If $iLivestreamerInstalled Then
	Local $iGuiWidth = 420, $iGuiHeight = 70

	If Random(0, 1, 1) Then
		$hGuiClipboard = GUICreate("To infinity... and beyond!", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	Else
		$hGuiClipboard = GUICreate("Copy Livestreamer compatible link to clipboard", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	EndIf

	$idLabel = GUICtrlCreateLabel("I am word", 70, 10, 350, 20)
	$idQuality = GUICtrlCreateCombo("", 70, 40, 160, 20)
	$idPlay = GUICtrlCreateButton("Play", 240, 40, 80, 20)
	GUICtrlSetOnEvent(-1, _GuiPlay)
	$idDownload = GUICtrlCreateButton("Download", 330, 40, 80, 20)
	GUICtrlSetOnEvent(-1, _GuiDownload)

	GUISetOnEvent($GUI_EVENT_CLOSE, _Hide)
EndIf

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
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
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
		$sUrl = $sBaseUrl & OPTIONS_OFFSET_LIMIT_TWITCH($iOffset, $iLimit) & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07"
		$avTemp = FetchItems($sUrl, "follows")
		If UBound($avTemp) = 0 Then ExitLoop

		Local $sOptions = ""
		For $iX = 0 To UBound($avTemp) -1
			$oChannel = Json_ObjGet($avTemp[$iX], "channel")
			$sName = Json_ObjGet($oChannel, "name")
			$sOptions &= $sName & ','
		Next

		$sOptions = StringTrimRight($sOptions, 1)
		$sUrl = 'https://api.twitch.tv/kraken/streams?channel=' & $sOptions & '&limit=' & $iLimit & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07"
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

		If UBound($avTemp) <> 100 Then ExitLoop

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
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
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

		$sThumbnail = "http://edge.sf.hitbox.tv" & Json_ObjGet($oLivestream[$iX], "media_thumbnail")

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

	ConsoleWrite("myURL " & $sUrl & @CRLF)

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
	For $iX = 1 To 3
		$dJsonString = InetRead($sUrl, $INET_FORCERELOAD)
		If @error = 0 Then ExitLoop
	Next
	If @error Then ConsoleWrite("All downloads failed" & @CRLF)

	If $iPrintJSON Then
		ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
		ConsoleWrite(BinaryToString($dJsonString) & @CRLF)
	EndIf

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
			Local $sDisplayName = $aStreams[$iX][$eDisplayName]
			If StringInStr($sFavorites, $aStreams[$iX][$eUrl] & ";") Then $sDisplayName = "[F] " & $sDisplayName
			If StringInStr($sIgnore, $aStreams[$iX][$eUrl] & ";") Then $sDisplayName = "[i] " & $sDisplayName

			Local $sTrayText = $sDisplayName
			If $aStreams[$iX][$eGame] <> "" Then $sTrayText &= " | " & $aStreams[$iX][$eGame]

			If $aStreams[$iX][$eTrayId] = 0 Then
				$aStreams[$iX][$eTrayId] = TrayCreateItem($sTrayText, -1, 0)
				If StringLeft($sDisplayName, 4) <> "[i] " Then
					Local $NewText = $aStreams[$iX][$eDisplayName]
					If $aStreams[$iX][$eGame] <> "" And $bBlobFirstRun <> true Then $NewText &= " | " & $aStreams[$iX][$eGame]

					$sNew &= $NewText & @CRLF
				EndIf
				TrayItemSetOnEvent( -1, _TrayStuff)
			Else
				TrayItemSetText($aStreams[$iX][$eTrayId], $sTrayText)
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
			Local $asText[] = ["I am unfinished", _
			"Ouch", _
			"Quit poking me!", _
			"Bewbs", _
			"Pizza", _
			"25W lightbulb (broken)", _
			"Estrellas Salt & Vin" & Chr(0xE4) & 'ger chips ' & Chr(0xE4) & "r godast", _
			"Vote Pewdiepie for King of Sweden", _
			"Vote Robbaz for King of Sweden", _
			"Vote Anderz for King of Sweden", _
			"I'm sorry trancexx", _
			"Vote Knugen for King of Sweden", _
			'"Is it creepy that I follow you, should I stop doing it?" - Xandy', _
			'"I can''t be expected to perform under pressure!" - jaberwacky', _
			'"The square root of 76 is brown" - One F Jef', _
			"42", _
			'"THERE... ARE... FOUR LIGHTS!" - Picard', _
			'"A. I was jogging, B. your cousin''s a liar, and C. some peacocks are poisonous" - Dennis Finch', _
			'"If you ever take advice from a duck, remember: Don''t. Ducks can''t talk. You''re probably on drugs" - Pewdiepie', _
			'"There''s always a story" - Richard Castle', _
			'"It''s my pony. You can''t pet it" - Richard Castle', _
			'"You kids get off my spawn!" - Generikb', _
			'"I prefer tentacles" - TheRPGMinx', _
			'"Learn to fall!" - Generikb''s dad to Generikb after he fell and broke his arm', _
			'"Get out of the way planet, I''m gonna punch you in the dick!" - One F Jef', _
			'"Everything on the internet is a lie" - Abraham Lincoln... (One F Jef)', _
			'"If someone''s breathing fire on your eyes you should tell an adult immediately" - MattShea', _
			'"I didn''t realize who I was until I stopped being who I wasn''t" - Unknown', _
			'"I don''t have time to get lucky" - Scetchlink', _
			'"It''s coming and so am I" - Scetchlink', _
			'"Thanks for playing with me, I appreciate it" - Scetchlink', _
			'"Go Flamesh*t with an Apethrower" - One F Jef 2016', _
			'"Som tur va hade jag en s' & Chr(0xE5) & ' v' & Chr(0xE4) & 'lbakad prilla, s' & Chr(0xE5) & ' den fungerade som airbag" - Ragge', _
			@CRLF & @CRLF & "Hej d" & Chr(0xE5) & " Svartnos." & @CRLF & "Du var min b" & Chr(0xE4) & "sta v" & Chr(0xE4) & "n i 19 " & Chr(0xE5) & "r." & @CRLF & "Jag saknar dig." & @CRLF & "Du kommer alltid att ha en plats i mitt hj" & Chr(0xE4) & "rta." & @CRLF & "RIP Svartnos - 4 Juli 2016."]

			$iRandom = Random(0, UBound($asText) -1, 1)
			MsgBox(0, @ScriptName, "Add text here" & @CRLF & @CRLF & "Created by Alexander Samuelsson AKA AdmiralAlkex" & @CRLF & @CRLF & "[" & $iRandom +1 & "/" & UBound($asText) & "] " & $asText[$iRandom])
		Case $idRefresh
			_MAIN()
		Case $idClipboard
			Local $sClipboard = ClipGet()
			Local $asStream[2] = [$sClipboard, $sClipboard]
			_ClipboardGo($asStream)
		Case $idExit
			If $sFavorites <> $sOldFavorites Then IniWrite(@ScriptDir & "\Settings.ini", "Section", "Favorites", $sFavorites)
			If $sIgnore <> $sOldIgnore Then IniWrite(@ScriptDir & "\Settings.ini", "Section", "Ignore", $sIgnore)
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
				If _IsPressed("10") Then
					Local $asStream[2] = [$aStreams[$iX][$eUrl], $aStreams[$iX][$eDisplayName]]
					_ClipboardGo($asStream)
				ElseIf _IsPressed("11") Then
					$sUrl = $sUrl & ";"

					If StringInStr($sFavorites, $sUrl) Then
						$sFavorites = StringReplace($sFavorites, $sUrl, "")
						$sIgnore &= $sUrl
					ElseIf StringInStr($sIgnore, $sUrl) Then
						$sIgnore = StringReplace($sIgnore, $sUrl, "")
					Else
						$sFavorites &= $sUrl
					EndIf

					Local $sDisplayName = $aStreams[$iX][$eDisplayName]
					If StringInStr($sFavorites, $aStreams[$iX][$eUrl] & ";") Then $sDisplayName = "[F] " & $sDisplayName
					If StringInStr($sIgnore, $aStreams[$iX][$eUrl] & ";") Then $sDisplayName = "[i] " & $sDisplayName
					;Shouldn't this also have an if not game then skip game display?
					TrayItemSetText($aStreams[$iX][$eTrayId], $sDisplayName & " | " & $aStreams[$iX][$eGame])
				Else
					$sQuality = "best,1080p60"
					Run("livestreamer --hls-segment-threads 2 " & $sUrl & " " & $sQuality, "", @SW_HIDE)
				EndIf
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
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
	ConsoleWrite("Getters done" & @CRLF)
	_TrayRefresh()
	;https://www.autoitscript.com/forum/topic/146955-solved-remove-crlf-at-the-end-of-text-file/?do=findComment&comment=1041088
	If StringRight($sNew, 2) = @CRLF Then $sNew = StringTrimRight($sNew, 2)
	If (Not @Compiled) Then
		TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
	Else
		TraySetIcon()
	EndIf

	If $sNew <> "" Then
		If $bBlobFirstRun = True Then
			$bBlobFirstRun = False
			Local $sReplaced = StringReplace($sNew, @CRLF, ", ")

			;Win 10 November Update seems to have a 140 character limit when just a block of text, but here spaces and things screw that up.
			;I'm guessing 120 is low enough to cover most situations.
			$sReplaced = StringLeft($sReplaced, 120)
			$sReplaced &= "..."
			TrayTip("Now streaming", $sReplaced, 10)
		ElseIf @OSBuild >= 10240 Then
			$asSplit = StringSplit($sNew, @CRLF, $STR_ENTIRESPLIT)
			For $iX = 1 To $asSplit[0]
				TrayTip("Now streaming", $asSplit[$iX], 10)
			Next
		Else
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
	EndIf

	AdlibRegister(_MAIN, $iRefresh)
EndFunc

Func _GuiPlay()
	$sQuality = GUICtrlRead($idQuality)
	If $sQuality = "" Then $sQuality = "best,1080p60"

	Run("livestreamer --hls-segment-threads 2 " & $sUrl & " " & $sQuality, "", @SW_HIDE)
EndFunc

Func _GuiDownload()
	$sPathToFile = FileSaveDialog("Save Stream to", "", "Video files (*.mp4)")

	$sQuality = GUICtrlRead($idQuality)
	If $sQuality = "" Then $sQuality = "best,1080p60"

	$iPid = Run('livestreamer -o "' & $sPathToFile & """ --hls-segment-threads 4 " & $sUrl & " " & $sQuality, "", @SW_HIDE, BitOR($STDOUT_CHILD, $STDERR_CHILD))
	$sFile = StringTrimLeft($sPathToFile, StringInStr($sPathToFile, "\", Default, -1))

	$hGui = GUICreate($sFile, 500, 1, -1, -1, BitOR($WS_MINIMIZEBOX, $WS_VISIBLE, $WS_SIZEBOX))
	GUISetOnEvent($GUI_EVENT_CLOSE, _StopDownload)

	If @Compiled Then
		GUISetIcon(@ScriptFullPath)
	Else
		GUISetIcon(@ScriptDir & "\Svartnos.ico")
	EndIf
	GUICtrlCreateLabel("Nothing to see here ;)", 10, 10)

	Local $avData[1][2] = [[$iPid, $hGui]]
	_ArrayAdd($avDownloads, $avData)

	AdlibRegister(_GuiDownloadAdlib)
EndFunc

Func _GuiDownloadAdlib()
	For $iX = UBound($avDownloads) -1 To 1 Step -1
		$sOutput = StderrRead($avDownloads[$iX][0])
		If @error Then
			GUIDelete($avDownloads[$iX][1])
			_ArrayDelete($avDownloads, $iX)
			ContinueLoop
		EndIf

		If $sOutput <> "" Then WinSetTitle($avDownloads[$iX][1], "", StringStripWS(StringReplace($sOutput, "[download]", ""), BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING)))
	Next
EndFunc

Func _StopDownload()
	For $iX = 1 To UBound($avDownloads) -1
		If $avDownloads[$iX][1] = @GUI_WinHandle Then
			Run("TaskKill /PID " & $avDownloads[$iX][0], "", @SW_HIDE)   ;Not sure if taskkill sends a ctrl+c or not... But at least it works.
			GUIDelete($avDownloads[$iX][1])
			_ArrayDelete($avDownloads, $iX)
			Return
		EndIf
	Next
EndFunc

Func _ClipboardGo($asStream)
	Local $sTitle
	$sUrl = $asStream[0]

	If UBound($asStream) > 1 Then $sTitle &= $asStream[1]
	GUICtrlSetData($idLabel, $sTitle)

	GUICtrlSetState($idQuality, $GUI_HIDE)
	_GUICtrlComboBox_ResetContent($idQuality)

	If Not GUISetState(@SW_SHOW, $hGuiClipboard) Then WinActivate($hGuiClipboard)
	$asQualities = _GetQualities($sUrl)
	$sQualities = _ArrayToString($asQualities)

	Local $sDefault = "no default"
	If StringInStr($sQualities, "source") Then
		$sDefault = "source"
	ElseIf StringInStr($sQualities, "1080p60") Then
		$sDefault = "1080p60"
	ElseIf StringInStr($sQualities, "Error") Then
		$sDefault = "Error"
	ElseIf $sDefault = "no default" Then
		ConsoleWrite("No default quality" & @CRLF)
		$sDefault = $asQualities[UBound($asQualities) -1]
	EndIf

	GUICtrlSetData($idQuality, $sQualities, $sDefault)

	GUICtrlSetState($idQuality, $GUI_SHOW)
EndFunc

Func _Hide()
	GUISetState(@SW_HIDE, $hGuiClipboard)
EndFunc
#EndRegion GUI

#Region INTENRAL INTERLECT
Func _StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $iService)
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
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

	If Not IsArray($aStreams[$iIndex][$eQualities]) Then
;~ 		$aStreams[$iIndex][$eQualities] = _GetQualities($sUrl)
	EndIf
EndFunc

Func _LivestreamerCanHandle($sUrl)
	$iExitCode = RunWait("livestreamer --can-handle-url " & $sUrl, "", @SW_HIDE)
	Return ($iExitCode = 0)
EndFunc

Func _GetQualities($sUrl)
	If $iLivestreamerInstalled = False Then Return ""

	Local $asError[] = ["Error"]

	If Not _LivestreamerCanHandle($sUrl) Then Return $asError

	$iPID = Run("livestreamer --json " & $sUrl, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)

	$oJSON = Json_Decode($sOutput)
	If IsObj($oJSON) = False Then Return $asError

	$aoStreams = Json_ObjGet($oJSON, "streams")
	If IsObj($aoStreams) = False Then Return $asError

	Local $asQualities[0]
	For $vItem In $aoStreams
		If $vItem = "best" Or $vItem = "worst" Then ContinueLoop
		_ArrayAdd($asQualities, $vItem)
	Next

	_ArraySort($asQualities)
	Return $asQualities
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
	If $aRet[1] <= 2 Then Return   ;Version

	_StreamSet("Update found! Click to open website", "https://github.com/TzarAlkex/StreamHelper/releases", "", "", "", "", "", $eLink)
EndFunc
#EndRegion
