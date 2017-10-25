#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Svartnos.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=StreamHelper
#AutoIt3Wrapper_Res_Fileversion=1.1.0.0
#AutoIt3Wrapper_Res_ProductVersion=1.1.0.0
#AutoIt3Wrapper_Res_LegalCopyright=My right shoe
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so /mi=100
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2 (Stable)
 Author:         Alexander Samuelsson AKA AdmiralAlkex

 Script Function:
	Stuff



Activate Twitch support on streamlink by running the following in cmd:
streamlink --twitch-oauth-authenticate



Todo:
*Add back the quality stuff in the array now that Twitch changed how they allocate transcoding to non-partners?
*Always save quality stuff to array for partners?
*Beep confirmed as annoying.

*BroccoliCat on twitch doesn't load properly on source quality in livestreamer.
Increase the timer wait thing in the config file?
I have increased multiple seconds, difference is questionable?
(needs to be verified if it still happens with streamlink!)

*ItsNatashaFFS sometimes just doesn't open with livestreamer.
The cmd and python processes start but just doesn't seem to do anything.
My only idea is that she went offline just as I started and that livestreamer maybe doesn't handle offline streams well.
(needs to be verified if it still happens with streamlink!)

*Favs changing games make the sound but not the notification?

*Add a check for when twitch says it returns x items and there is not x items in the response array (and log it!)

#ce ----------------------------------------------------------------------------

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
#include <File.au3>
#include <GuiEdit.au3>
#include <UpDownConstants.au3>
#include "WinHttp.au3"
#include <GuiMenu.au3>

If _Singleton("AutoIt window with hopefully a unique title|Ketchup the second", 1) = 0 Then
	$iWM = _WinAPI_RegisterWindowMessage("AutoIt window with hopefully a unique title|Ketchup the second")
	_WinAPI_PostMessage(WinGetHandle("AutoIt window with hopefully a unique title|Senap the third"), $iWM, 0, 0)
	Exit
EndIf

If (Not @Compiled) Then
	TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
EndIf

$iClosePreviousBeforePlaying = True

$sLog = RegRead("HKCU\SOFTWARE\StreamHelper\", "Log")
Global $sInstallType = _InstallType()
_CW("Install type: " & $sInstallType)

$sUpdateCheck = RegRead("HKCU\SOFTWARE\StreamHelper\", "UpdateCheck")
If @error Then
	$sUpdateCheck = "Daily"
EndIf
If $sInstallType = "AppX" Then
	$sUpdateCheck = "Never"
EndIf
$sCheckTime = RegRead("HKCU\SOFTWARE\StreamHelper\", "CheckTime")
If @error Then $sCheckTime = "0"
$sRefreshMinutes = RegRead("HKCU\SOFTWARE\StreamHelper\", "RefreshMinutes")
If @error Then $sRefreshMinutes = 3

$sTwitchId = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchId")
$sTwitchName = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchName")
$sMixerId = RegRead("HKCU\SOFTWARE\StreamHelper\", "MixerId")
$sMixerName = RegRead("HKCU\SOFTWARE\StreamHelper\", "MixerName")
$sSmashcastId = RegRead("HKCU\SOFTWARE\StreamHelper\", "SmashcastId")
$sSmashcastName = RegRead("HKCU\SOFTWARE\StreamHelper\", "SmashcastName")

Global $sFavoritesNew = RegRead("HKCU\SOFTWARE\StreamHelper\", "Favorites")
If $sFavoritesNew <> "" Then $sFavoritesNew &= @LF
Global $sOldFavoritesNew = $sFavoritesNew
Global $sIgnoreNew = RegRead("HKCU\SOFTWARE\StreamHelper\", "Ignore")
If $sIgnoreNew <> "" Then $sIgnoreNew &= @LF
Global $sOldIgnoreNew = $sIgnoreNew

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)
Opt("GUIOnEventMode", 1)

TrayCreateItem("")
Local $idRefresh = TrayCreateItem("Refresh")
TrayItemSetOnEvent( -1, _TrayStuff)

Local $idClipboard = TrayCreateItem("Play from clipboard")
TrayItemSetOnEvent( -1, _TrayStuff)

TrayCreateItem("")
Local $idSettings = TrayCreateItem("Settings")
TrayItemSetOnEvent( -1, _TrayStuff)

Local $idAbout = TrayCreateItem("About")
TrayItemSetOnEvent( -1, _TrayStuff)

Local $idExit = TrayCreateItem("Exit")
TrayItemSetOnEvent( -1, _TrayStuff)

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime, $eOnline, $eService, $eQualities, $eFlags, $eUserID, $eMax
Global Enum $eTwitch, $eSmashcast, $eMixer
Global Enum Step *2 $eVodCast, $eIsLink, $eIsText, $eIsStream

Global $sNew
Global $aStreams[0][$eMax]

Global $iStreamlinkInstalled = StringInStr(EnvGet("path"), "Streamlink") > 0
Global $bBlobFirstRun = True

Global $bFavoriteFound = False
Global $sChanged

Global Const $AUT_WM_NOTIFYICON = $WM_USER + 1 ; Application.h
Global Const $AUT_NOTIFY_ICON_ID = 1 ; Application.h
Global Const $PBT_APMRESUMEAUTOMATIC =  0x12

AutoItWinSetTitle("AutoIt window with hopefully a unique title|Ketchup the second")
Global $TRAY_ICON_GUI = WinGetHandle(AutoItWinGetTitle()) ; Internal AutoIt GUI
Global $avDownloads[1][2]

Global $hGuiClipboard
Global $idLabel, $idQuality, $idUrl
_GuiCreate()

Global $hGuiSettings
Global $idRefreshMinutes, $idUpdates, $idLog, $idTwitchInput, $idTwitchId, $idTwitchName, $idMixerInput, $idMixerId, $idMixerName, $idSmashcastInput, $idSmashcastId, $idSmashcastName
_SettingsCreate()

_GDIPlus_Startup()

Global $hBitmap, $hImage, $hGraphic
$hBitmap = _WinAPI_CreateSolidBitmap(0, 0xFFFFFF, 16, 16)
$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
$hGraphic = _GDIPlus_ImageGetGraphicsContext($hImage)

_MAIN()

GUICreate("AutoIt window with hopefully a unique title|Senap the third")
GUIRegisterMsg($WM_POWERBROADCAST, "_PowerEvents")
GUIRegisterMsg($WM_ENDSESSION, "_EndSessionEvents")
$iWM = _WinAPI_RegisterWindowMessage("AutoIt window with hopefully a unique title|Ketchup the second")
GUIRegisterMsg($iWM, "_RemoteEvents")

While 1
	Sleep(3600000)
WEnd

#Region TWITCH
Func _TwitchNew()
	_CW("Twitching")
	_ProgressSpecific("T")

	_TwitchNewGet()

	_TwitchGetGames()

	$iTrayRefresh = True
EndFunc

Func _TwitchNewGet()
	$sCursor = ""

	While True
		$sUrl = "users/follows?from_id=" & $sTwitchId & "&first=100&after=" & $sCursor
		$oJSON = _TwitchNewDownload($sUrl)
		If IsObj($oJSON) = False Then Return

		$aData = Json_ObjGet($oJSON, "data")
		If UBound($aData) = 0 Then ExitLoop

		$oPagination = Json_ObjGet($oJSON, "pagination")
		$sCursor = Json_ObjGet($oPagination, "cursor")

		Local $sUsers = ""
		For $iX = 0 To UBound($aData) -1
			$sUser = Json_ObjGet($aData[$iX], "to_id")
			$sUsers &= $sUser & ','
		Next

		$sUsers = StringTrimRight($sUsers, 1)
		$sUrl = 'https://api.twitch.tv/kraken/streams/?channel=' & $sUsers & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"
		$aoStreams = FetchItems($sUrl, "streams")
		If UBound($aoStreams) = 0 Then ExitLoop

		For $iX = 0 To UBound($aoStreams) -1
			$oChannel = Json_ObjGet($aoStreams[$iX], "channel")

			$sUrl = Json_ObjGet($oChannel, "url")
			$sName = Json_ObjGet($oChannel, "display_name")
			If StringIsASCII($sName) = 0 Then $sName = Json_ObjGet($oChannel, "name")
			$sGame = Json_ObjGet($oChannel, "game")
			$sUserID = "T" & Json_ObjGet($oChannel, "_id")

			Local $iFlags = $eIsStream
			If Json_ObjGet($aoStreams[$iX], "stream_type") = "watch_party" Then $iFlags = BitOR($iFlags, $eVodCast)

			_StreamSet($sName, $sUrl, "", $sGame, "", "", "", $eTwitch, $sUserID, $iFlags)
		Next
		If UBound($aData) <> 100 Then Return "Potato on a Stick"
	WEnd

	Return "Potato on a Stick"
EndFunc

Func _TwitchGetGames()
	$sUrl = "users?id=" & $sTwitchId
	$oJSON = _TwitchNewDownload($sUrl)
	If IsObj($oJSON) = False Then Return

	$aData = Json_ObjGet($oJSON, "data")
	If UBound($aData) <> 1 Then Return

	$sUserName = Json_ObjGet($aData[0], "login")
	If $sUserName = "" Then
		Return
	Else
		RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchName", "REG_SZ", $sUsername)
		$sTwitchName = $sUsername
	EndIf

	Local $sGamesUrl = "https://api.twitch.tv/api/users/" & $sUsername & "/follows/games/live?client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"

	$avTemp = FetchItems($sGamesUrl, "follows")
	If UBound($avTemp) = 0 Then Return

	For $iX = 0 To UBound($avTemp) -1
		$oGame = Json_ObjGet($avTemp[$iX], "game")
		$sName = Json_ObjGet($oGame, "name")

		$sUrl = 'https://api.twitch.tv/kraken/streams/?game=' & $sName & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"
		$oChannel = FetchItems($sUrl, "streams")

		For $iY = 0 To UBound($oChannel) -1
			$oChannel2 = Json_ObjGet($oChannel[$iY], "channel")

			$sUrl = Json_ObjGet($oChannel2, "url")
			$sName = Json_ObjGet($oChannel2, "display_name")
			If StringIsASCII($sName) = 0 Then $sName = Json_ObjGet($oChannel, "name")
			$sGame = Json_ObjGet($oChannel[$iY], "game")
			$sUserID = "T" & Json_ObjGet($oChannel2, "_id")

			_StreamSet($sName, $sUrl, "", $sGame, "", "", "", $eTwitch, $sUserID)
		Next
	Next
EndFunc

Func _TwitchNewDownload($sUrl)
	_CW("myURL " & $sUrl)

	Local $hOpen = _WinHttpOpen()
	Local $hConnect = _WinHttpConnect($hOpen, "api.twitch.tv")

	$asResponse = _WinHttpSimpleSSLRequest($hConnect, Default, "helix/" & $sUrl, Default, Default, "Client-ID: " & "i8funp15gnh1lfy1uzr1231ef1dxg07", True)

	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)

	_CW(StringReplace(StringStripWS($asResponse[0], $STR_STRIPTRAILING), @CRLF, " \ "))
	_CW($asResponse[1])

	$oJSON = Json_Decode($asResponse[1])
	Return $oJSON
EndFunc
#EndRegion TWITCH

#Region SMASHCAST
Func _Smashcast()
	_CW("Smashcasting")
	_ProgressSpecific("S")

	_SmashcastGet()

	$iTrayRefresh = True
EndFunc

Func _SmashcastGet()
	$iOffset = 0

	While 1
		Local $sUrl = "https://api.smashcast.tv/media/live/list?follower_id=" & $sSmashcastId & "&start=" & $iOffset
		$oLivestream = FetchItems($sUrl, "livestream")
		If UBound($oLivestream) = 0 Then Return

		For $iX = 0 To UBound($oLivestream) -1
			$oChannel = Json_ObjGet($oLivestream[$iX], "channel")
			$sUrl = Json_ObjGet($oChannel, "channel_link")
			$sUserID = "S" & Json_ObjGet($oChannel, "user_id")

			$sDisplayName = Json_ObjGet($oLivestream[$iX], "media_display_name")

			$sStatus = Json_ObjGet($oLivestream[$iX], "media_status")

			;The documentation still says to use the hitbox domain for images
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

			_StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $eSmashcast, $sUserID)
		Next
		If UBound($oLivestream) <> 100 Then Return "Potato on a Stick"
		$iOffset += 100
	WEnd

	Return "Potato on a Stick"
EndFunc
#EndRegion

#Region MIXER
Func _Mixer()
	_CW("Mixering")
	_ProgressSpecific("M")

	_MixerGet()

	$iTrayRefresh = True
EndFunc

Func _MixerGet()
	$iOffset = 0

	While 1
		Local $sUrl = "https://mixer.com/api/v1/users/" & $sMixerId & "/follows?page=" & $iOffset & "&limit=100&where=online:eq:1&fields=user,token,type&noCount=1"
		$oFollows = getJson($sUrl)
		If UBound($oFollows) = 0 Then Return

		For $iX = 0 To UBound($oFollows) -1
			$oUser = Json_ObjGet($oFollows[$iX], "user")
			$sDisplayName = Json_ObjGet($oUser, "username")
			$sUserID = "M" & Json_ObjGet($oUser, "id")

			$sUrl = "https://mixer.com/" & Json_ObjGet($oFollows[$iX], "token")

			$oType = Json_ObjGet($oFollows[$iX], "type")
			If IsObj($oType) Then
				$sGame = Json_ObjGet($oType, "name")
			Else
				$sGame = "No game selected"
			EndIf

			_StreamSet($sDisplayName, $sUrl, "", $sGame, "", "", "", $eMixer, $sUserID)
		Next
		If UBound($oFollows) <> 100 Then Return "Potato on a Stick"
		$iOffset += 1
	WEnd

	Return "Potato on a Stick"
EndFunc
#EndRegion

#Region COMMON
Func FetchItems($sUrl, $sKey)
	$oJSON = getJson($sUrl)

	If IsObj($oJSON) = False Then Return ""

	$aFollows = Json_ObjGet($oJSON, $sKey)
	If UBound($aFollows) > 0 Then
		Return $aFollows
	Else
		Return ""
	EndIf
EndFunc

Func FetchItem($sUrl, $sKey)
	$oJSON = getJson($sUrl)

	If IsObj($oJSON) = False Then Return ""

	$aFollows = Json_ObjGet($oJSON, $sKey)
	Return $aFollows
EndFunc

Func getJson($sUrl)
	_CW("myURL " & $sUrl)

	Local $sJson, $iError
	For $iX = 1 To 3
		$dJsonString = InetRead($sUrl, $INET_FORCERELOAD)
		$iError = @error
		_CW("Inet @error:" & $iError & " @extended: " & @extended & " BinaryLen: " & BinaryLen($dJsonString) & " StringLen: " & StringLen(BinaryToString($dJsonString)))
		If $iError = 0 Then ExitLoop
		If $iError = 13 Then ExitLoop   ;error 13 seems to mean the server rejected the download so no need to repeat
	Next
	If $iError Then _CW("All downloads failed")
	If $dJsonString = "" Then Return

	_CW($dJsonString)
	$sJson = BinaryToString($dJsonString)
	_CW($sJson)

	$oJSON = Json_Decode($sJson)
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
			If BitAND($aStreams[$iX][$eFlags], $eIsStream) Then
				If StringInStr($sFavoritesNew, $aStreams[$iX][$eUserID] & @LF) Then $sDisplayName = "[F] " & $sDisplayName
				If StringInStr($sIgnoreNew, $aStreams[$iX][$eUserID] & @LF) Then $sDisplayName = "[i] " & $sDisplayName
			EndIf
			If BitAND($aStreams[$iX][$eFlags], $eVodCast) Then $sDisplayName = "[v] " & $sDisplayName

			Local $sTrayText = $sDisplayName
			If $aStreams[$iX][$eGame] <> "" Then $sTrayText &= " | " & $aStreams[$iX][$eGame]

			$aStreams[$iX][$eOnline] = False

			If $aStreams[$iX][$eTrayId] = 0 Then
				$aStreams[$iX][$eTrayId] = TrayCreateItem($sTrayText, -1, 0)
				If $aStreams[$iX][$eFlags] = $eIsStream And StringInStr($sDisplayName, "[i] ", $STR_CASESENSE, 1, 1, 8) = 0 And StringInStr($sDisplayName, "[v] ", $STR_CASESENSE, 1, 1, 8) = 0 Then
					Local $NewText = $aStreams[$iX][$eDisplayName]
					If $aStreams[$iX][$eGame] <> "" And $bBlobFirstRun <> True Then $NewText &= " | " & $aStreams[$iX][$eGame]
					$sNew &= $NewText & @CRLF

					If StringInStr($sDisplayName, "[F] ", $STR_CASESENSE, 1, 1, 8) Then $bFavoriteFound = True
				EndIf
				TrayItemSetOnEvent( -1, _TrayStuff)
			Else
				If $sTrayText = TrayItemGetText($aStreams[$iX][$eTrayId]) Then ContinueLoop

				TrayItemSetText($aStreams[$iX][$eTrayId], $sTrayText)

				Local $NewText = $aStreams[$iX][$eDisplayName]
				If $aStreams[$iX][$eGame] <> "" Then $NewText &= " | " & $aStreams[$iX][$eGame]
				$sChanged &= $NewText & @CRLF

				If StringInStr($sDisplayName, "[F] ", $STR_CASESENSE, 1, 1, 8) Then $bFavoriteFound = True
			EndIf
		Else
			If $aStreams[$iX][$eTrayId] <> 0 And BitAND($aStreams[$iX][$eFlags], $eIsStream) = $eIsStream Then
				TrayItemDelete($aStreams[$iX][$eTrayId])
				$aStreams[$iX][$eTrayId] = 0
			EndIf
		EndIf
	Next
EndFunc

Func _TrayStuff()
	Switch @TRAY_ID
		Case $idSettings
			If Not GUISetState(@SW_SHOW, $hGuiSettings) Then WinActivate($hGuiSettings)
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
			Local $asStream[] = [$sClipboard]
			_ClipboardGo($asStream)
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

			If BitAND($aStreams[$iX][$eFlags], $eIsLink) = $eIsLink Then
				ShellExecute($sUrl)
			ElseIf BitAND($aStreams[$iX][$eFlags], $eIsText) = $eIsText Then
				Return
			ElseIf BitAND($aStreams[$iX][$eFlags], $eIsStream) = $eIsStream Then
				If _IsPressed("10") Then
					Local $asStream[] = [$aStreams[$iX][$eUrl], $aStreams[$iX][$eDisplayName]]
					_ClipboardGo($asStream)
				ElseIf _IsPressed("11") Then
					$sUserID = $aStreams[$iX][$eUserID] & @LF

					If StringInStr($sFavoritesNew, $sUserID) Then
						$sFavoritesNew = StringReplace($sFavoritesNew, $sUserID, "")
						$sIgnoreNew &= $sUserID
					ElseIf StringInStr($sIgnoreNew, $sUserID) Then
						$sIgnoreNew = StringReplace($sIgnoreNew, $sUserID, "")
					Else
						$sFavoritesNew &= $sUserID
					EndIf

					If $sFavoritesNew <> $sOldFavoritesNew Then
						RegWrite("HKCU\SOFTWARE\StreamHelper\", "Favorites", "REG_MULTI_SZ", StringStripWS($sFavoritesNew, $STR_STRIPTRAILING))
						$sOldFavoritesNew = $sFavoritesNew
					EndIf
					If $sIgnoreNew <> $sOldIgnoreNew Then
						RegWrite("HKCU\SOFTWARE\StreamHelper\", "Ignore", "REG_MULTI_SZ", StringStripWS($sIgnoreNew, $STR_STRIPTRAILING))
						$sOldIgnoreNew = $sIgnoreNew
					EndIf

					Local $sDisplayName = $aStreams[$iX][$eDisplayName]
					If StringInStr($sFavoritesNew, $aStreams[$iX][$eUserID] & @LF) Then $sDisplayName = "[F] " & $sDisplayName
					If StringInStr($sIgnoreNew, $aStreams[$iX][$eUserID] & @LF) Then $sDisplayName = "[i] " & $sDisplayName

					;Shouldn't this also have an if not game then skip game display?
					;Future me: Yes. Yes it should.
					Local $NewText = $sDisplayName
					If $aStreams[$iX][$eGame] <> "" Then $NewText &= " | " & $aStreams[$iX][$eGame]
					TrayItemSetText($aStreams[$iX][$eTrayId], $NewText)
				ElseIf $iStreamlinkInstalled And $aStreams[$iX][$eService] <> $eMixer Then
					_StreamlinkPlay($sUrl)
				Else
					ShellExecute($sUrl)
				EndIf
			EndIf
	EndSwitch
EndFunc

Func _StreamlinkPlay($sUrl, $sQuality = "")
	Static Local $iPID = 0
	;_GuiPlay can send empty $sQuality so conversion has to be done
	If $sQuality = "" Then $sQuality = "best"

	If $iClosePreviousBeforePlaying Then
		If _WinAPI_GetProcessName($iPID) = "streamlink.exe" Then
			RunWait("taskkill.exe /PID " & $iPID & " /T", "", @SW_HIDE)
			ProcessWaitClose($iPID, 1000)
		EndIf
	EndIf

	$iPID = Run("streamlink.exe --twitch-disable-hosting " & $sUrl & " " & $sQuality, "", @SW_HIDE)
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

	If (Not _WinAPI_IsInternetConnected()) Then
		AdlibRegister(_WaitForInternet)
		Return
	EndIf

	Global $sNew = "", $sChanged = ""
	_CheckUpdates()

	If $sTwitchId <> "" Then _TwitchNew()
	If $sMixerId <> "" Then _Mixer()
	If $sSmashcastId <> "" Then _Smashcast()

	_CW("Getters done")
	_TrayRefresh()

	;https://www.autoitscript.com/forum/topic/146955-solved-remove-crlf-at-the-end-of-text-file/?do=findComment&comment=1041088
	If StringRight($sNew, 2) = @CRLF Then $sNew = StringTrimRight($sNew, 2)
	If (Not @Compiled) Then
		TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
	Else
		TraySetIcon()
	EndIf

	If $bFavoriteFound = True Then
		SoundPlay(@ScriptDir & "\Authentic A-10 Warthog sounds TM.wav")
		$bFavoriteFound = False
	EndIf

	If $sChanged <> "" Then
		If @OSBuild >= 10240 Then
			$iSkipped = 0
			While StringLen($sChanged) > 140
				$iPos = StringInStr($sChanged, @CRLF, $STR_CASESENSE, -1)
				$sChanged = StringLeft($sChanged, $iPos -1)
				$iSkipped += 1
			WEnd
			If $iSkipped > 0 Then
				$sChanged &= @CRLF & "+" & $iSkipped & " more"
			EndIf

			TrayTip("Changed game", $sChanged, 10)
		Else
			$iSkipped = 0
			While StringLen($sChanged) > 240
				$iPos = StringInStr($sChanged, @CRLF, $STR_CASESENSE, -1)
				$sChanged = StringLeft($sChanged, $iPos -1)
				$iSkipped += 1
			WEnd
			If $iSkipped > 0 Then
				$sChanged &= @CRLF & "+" & $iSkipped & " more"
			EndIf

			TrayTip("Changed game", $sChanged, 10)
		EndIf
	EndIf

	If $sNew <> "" Then
		If $bBlobFirstRun = True Then
			$bBlobFirstRun = False
			Local $sReplaced = StringReplace($sNew, @CRLF, ", ")
			Local $iReplacedLength = StringLen($sReplaced)

			;Win 10 November Update seems to have a 140 character limit when just a block of text, but here spaces and things screw that up.
			;I'm guessing 120 is low enough to cover most situations.
			$sReplaced = StringLeft($sReplaced, 120)
			If StringLen($sReplaced) <> $iReplacedLength Then $sReplaced &= "..."
			TrayTip("Now streaming", $sReplaced, 10)
		ElseIf @OSBuild >= 10240 Then
			$iSkipped = 0
			While StringLen($sNew) > 140
				$iPos = StringInStr($sNew, @CRLF, $STR_CASESENSE, -1)
				$sNew = StringLeft($sNew, $iPos -1)
				$iSkipped += 1
			WEnd
			If $iSkipped > 0 Then
				$sNew &= @CRLF & "+" & $iSkipped & " more"
			EndIf

			TrayTip("Now streaming", $sNew, 10)
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

	AdlibRegister(_MAIN, $sRefreshMinutes * 60000)
EndFunc

;Sort every array by length to move overrun to the end? What if there is multiple long lines?
;https://www.autoitscript.com/forum/topic/177643-how-to-sort-a-array-by-string-length/
Func _TrayTipThis($sPeople, $sDesc, $iLines)
	$asSplit = StringSplit($sPeople, @CRLF, $STR_ENTIRESPLIT + $STR_NOCOUNT)

	While True
		Local $asText[0]
		For $iX = 1 To $iLines
			$sPopped = _ArrayPop($asSplit)
			If @error Then
				TrayTip($sDesc, _ArrayToString($asText, @CRLF), 10)
				Return
			Else
				_ArrayAdd($asText, $sPopped, Default, Default, Default, $ARRAYFILL_FORCE_SINGLEITEM)
			EndIf
		Next
		TrayTip($sDesc, _ArrayToString($asText, @CRLF), 10)
	WEnd
EndFunc

Func _TrayTipThis2($sPeople, $sDesc, $iLines)
	While True
		$iLocation = StringInStr($sPeople, @CRLF, $STR_NOCASESENSEBASIC, $iLines)
		If $iLocation = 0 Then
			TrayTip($sDesc, $sPeople, 10)
			ExitLoop
		Else
			$sText = StringLeft($sPeople, $iLocation -1)
			$sPeople = StringTrimLeft($sPeople, $iLocation +1)
			TrayTip($sDesc, $sText, 10)
		EndIf
	WEnd
EndFunc

Func _TrayTipThis3($sPeople, $sDesc, $iLines)
	$asSplit = StringSplit($sPeople, @CRLF, $STR_ENTIRESPLIT)

	For $iX = 1 To $asSplit[0] Step $iLines
		Local $sText = ""
		For $iY = 1 To $iLines
			$sText &= $asSplit[$iX+$iY] & @CRLF
		Next
		$sText = StringTrimRight($sText, 2)
		TrayTip($sDesc, $sText, 10)
	Next
EndFunc

Func _GuiCreate()
	Local $iGuiWidth = 510, $iGuiHeight = 70

	If Random(0, 1, 1) Then
		$hGuiClipboard = GUICreate("To infinity... and beyond!", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	Else
		$hGuiClipboard = GUICreate("Copy Streamlink compatible link to clipboard", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	EndIf

	$idLabel = GUICtrlCreateLabel("I am word", 70, 10, 350, 20)
	$idQuality = GUICtrlCreateCombo("", 70, 40, 160, 20)
	$idPlay = GUICtrlCreateButton("Play", 240, 40, 60, 20)
	GUICtrlSetOnEvent(-1, _GuiPlay)
	$idDownload = GUICtrlCreateButton("Download", 310, 40, 80, 20)
	GUICtrlSetOnEvent(-1, _GuiDownload)
	$idBrowser = GUICtrlCreateButton("Open in browser", 400, 40, 100, 20)
	GUICtrlSetOnEvent(-1, _GuiBrowser)
	$idUrl = GUICtrlCreateDummy()

	GUISetOnEvent($GUI_EVENT_CLOSE, _Hide)
EndFunc

Func _GuiPlay()
	Local $sQuality = GUICtrlRead($idQuality)
	Local $sUrl = GUICtrlRead($idUrl)

	_StreamlinkPlay($sUrl, $sQuality)
EndFunc

Func _GuiDownload()
	$sPathToFile = FileSaveDialog("Save Stream to", "", "Video files (*.mp4)")
	If @error Then Return

	$sQuality = GUICtrlRead($idQuality)
	If $sQuality = "" Then $sQuality = "best"

	Local $sUrl = GUICtrlRead($idUrl)

	$iPid = Run('streamlink.exe --twitch-disable-hosting --output "' & $sPathToFile & """ " & $sUrl & " " & $sQuality, "", @SW_HIDE, BitOR($STDOUT_CHILD, $STDERR_CHILD))
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
			Run("taskkill.exe /PID " & $avDownloads[$iX][0], "", @SW_HIDE)   ;Not sure if taskkill sends a ctrl+c or not... But at least it works.
			GUIDelete($avDownloads[$iX][1])
			_ArrayDelete($avDownloads, $iX)
			Return
		EndIf
	Next
EndFunc

Func _GuiBrowser()
	Local $sUrl = GUICtrlRead($idUrl)
	ShellExecute($sUrl)
EndFunc

Func _ClipboardGo($asStream)
	Local $sTitle
	Local $sUrl = $asStream[0]

	If $iStreamlinkInstalled = False Then
		If MsgBox($MB_YESNO, @ScriptName, "Streamlink not found, open url in browser instead?") = $IDYES Then
			ShellExecute($sUrl)
		EndIf
		Return
	EndIf

	If UBound($asStream) > 1 Then $sTitle &= $asStream[1]

	GUICtrlSetData($idLabel, $sTitle)
	GUICtrlSendToDummy($idUrl, $sUrl)

	GUICtrlSetState($idQuality, $GUI_HIDE)
	_GUICtrlComboBox_ResetContent($idQuality)

	If Not GUISetState(@SW_SHOW, $hGuiClipboard) Then WinActivate($hGuiClipboard)

	$asQualities = _GetQualities($sUrl)
	$sQualities = _ArrayToString($asQualities)

	Local $sDefault = "no default"
	If StringInStr($sQualities, "Error") Then
		$sDefault = "Error"
	ElseIf $sDefault = "no default" Then
		$sDefault = $asQualities[UBound($asQualities) -1]
	EndIf

	GUICtrlSetData($idQuality, $sQualities, $sDefault)

	GUICtrlSetState($idQuality, $GUI_SHOW)
EndFunc

Func _Hide()
	GUISetState(@SW_HIDE, $hGuiClipboard)
EndFunc
#EndRegion GUI

#Region SETTINGS-GUI
Func _SettingsCreate()
	Local $iGuiWidth = 430, $iGuiHeight = 220
	$hGuiSettings = GUICreate("StreamHelper - Settings", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	If @Compiled = False Then GUISetIcon(@ScriptDir & "\Svartnos.ico")

	GUICtrlCreateTab(10, 10, $iGuiWidth - 20, $iGuiHeight - 20)

	GUICtrlCreateTabItem("Settings")

	GUICtrlCreateLabel("Minutes between refresh", 20, 40)
	$idRefreshMinutes = GUICtrlCreateInput($sRefreshMinutes, 20, 60, 80)
	GUICtrlCreateUpdown(-1, $UDS_ARROWKEYS)
	GUICtrlSetLimit(-1, 120, 1)

	If $sInstallType <> "AppX" Then
		GUICtrlCreateLabel("Check for updates", 20, 90)
		$idUpdates = GUICtrlCreateCombo("", 20, 110, 80)
		GUICtrlSetData(-1, "Never|Daily|Weekly|Monthly", $sUpdateCheck)
	EndIf

	$idLog = GUICtrlCreateCheckbox("Save log to file (don't enable unless asked)", 20, 140)
	If $sLog = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateTabItem("Twitch")
	GUICtrlCreateLabel("1. Input username" & @CRLF & "2. Click Get ID", 20, 40)

	GUICtrlCreateLabel(" ", 20, 70)
	$idTwitchInput = GUICtrlCreateInput("", 20, 90, 190)
	_GUICtrlEdit_SetCueBanner($idTwitchInput, "Username")
	GUICtrlCreateButton("Get ID", 20, 120)
	GUICtrlSetOnEvent(-1, _TwitchGetId)
	GUICtrlCreateButton("Reset", 155, 120)
	GUICtrlSetOnEvent(-1, _TwitchReset)

	GUICtrlCreateLabel("Saved ID", 20, 160)
	$idTwitchId = GUICtrlCreateInput($sTwitchId, 20, 180, 120, Default, $ES_READONLY)
	GUICtrlCreateLabel("Saved Username", 155, 160)
	$idTwitchName = GUICtrlCreateInput($sTwitchName, 155, 180, 120, Default, $ES_READONLY)

	GUICtrlCreateTabItem("Mixer")
	GUICtrlCreateLabel("1. Input username" & @CRLF & "2. Click Get ID", 20, 40)

	GUICtrlCreateLabel(" ", 20, 70)
	$idMixerInput = GUICtrlCreateInput("", 20, 90, 190)
	_GUICtrlEdit_SetCueBanner($idMixerInput, "Username")
	GUICtrlCreateButton("Get ID", 20, 120)
	GUICtrlSetOnEvent(-1, _MixerGetId)
	GUICtrlCreateButton("Reset", 155, 120)
	GUICtrlSetOnEvent(-1, _MixerReset)

	GUICtrlCreateLabel("Saved ID", 20, 160)
	$idMixerId = GUICtrlCreateInput($sMixerId, 20, 180, 120, Default, $ES_READONLY)
	GUICtrlCreateLabel("Saved Username", 155, 160)
	$idMixerName = GUICtrlCreateInput($sMixerName, 155, 180, 120, Default, $ES_READONLY)

	GUICtrlCreateTabItem("Smashcast")
	GUICtrlCreateLabel("1. Input username" & @CRLF & "2. Click Get ID", 20, 40)

	GUICtrlCreateLabel(" ", 20, 70)
	$idSmashcastInput = GUICtrlCreateInput("", 20, 90, 190)
	_GUICtrlEdit_SetCueBanner($idSmashcastInput, "Username")
	GUICtrlCreateButton("Get ID", 20, 120)
	GUICtrlSetOnEvent(-1, _SmashcastGetId)
	GUICtrlCreateButton("Reset", 155, 120)
	GUICtrlSetOnEvent(-1, _SmashcastReset)

	GUICtrlCreateLabel("Saved ID", 20, 160)
	$idSmashcastId = GUICtrlCreateInput($sSmashcastId, 20, 180, 120, Default, $ES_READONLY)
	GUICtrlCreateLabel("Saved Username", 155, 160)
	$idSmashcastName = GUICtrlCreateInput($sSmashcastName, 155, 180, 120, Default, $ES_READONLY)

	GUICtrlCreateTabItem("")

	GUISetOnEvent($GUI_EVENT_CLOSE, _SettingsHide)
EndFunc

Func _SettingsRefresh()
	Local $sNew = GUICtrlRead($idRefreshMinutes)
	If $sNew = $sRefreshMinutes Then Return
	$sRefreshMinutes = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "RefreshMinutes", "REG_SZ", $sRefreshMinutes)
EndFunc

Func _SettingsUpdateCheck()
	Local $sNew = GUICtrlRead($idUpdates)
	If $sNew = $sUpdateCheck Then Return
	$sUpdateCheck = $sNew
	$sCheckTime = 0
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "UpdateCheck", "REG_SZ", $sUpdateCheck)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "CheckTime", "REG_SZ", 0)
EndFunc

Func _SettingsLog()
	Local $sNew = BitAND(GUICtrlRead($idLog), $GUI_CHECKED)
	If $sNew = $sLog Then Return
	$sLog = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "Log", "REG_SZ", $sLog)
EndFunc

Func _TwitchGetId()
	$sUsername = GUICtrlRead($idTwitchInput)
	If $sUsername = "" Then Return _GetErrored()
	$sUsername = StringStripWS($sUsername, $STR_STRIPALL)
	$sQuotedUsername = URLEncode($sUsername)

	$oJSON = _TwitchNewDownload("users?login=" & $sQuotedUsername)
	If IsObj($oJSON) = False Then Return _GetErrored()

	$aData = Json_ObjGet($oJSON, "data")
	If UBound($aData) <> 1 Then Return _GetErrored()
	$iUserID = Json_ObjGet($aData[0], "id")

	If $iUserID <> "" Then
		_TwitchSet($iUserID, $sUsername)
	Else
		Return _GetErrored()
	EndIf
EndFunc

Func _TwitchReset()
	_TwitchSet("", "")
EndFunc

Func _TwitchSet($sId, $sName)
	$sTwitchId = $sId
	$sTwitchName = $sName
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchId", "REG_SZ", $sId)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchName", "REG_SZ", $sName)
	GUICtrlSetData($idTwitchId, $sId)
	GUICtrlSetData($idTwitchName, $sName)
EndFunc

Func _MixerGetId()
	$sUsername = GUICtrlRead($idMixerInput)
	If $sUsername = "" Then Return _GetErrored()
	$sUsername = StringStripWS($sUsername, $STR_STRIPALL)
	$sQuotedUsername = URLEncode($sUsername)
	$sUserUrl = "https://mixer.com/api/v1/channels/" & $sQuotedUsername
	$iUserID = FetchItem($sUserUrl, "userId")

	If $iUserID <> "" Then
		_MixerSet($iUserID, $sUsername)
	Else
		Return _GetErrored()
	EndIf
EndFunc

Func _MixerReset()
	_MixerSet("", "")
EndFunc

Func _MixerSet($sId, $sName)
	$sMixerId = $sId
	$sMixerName = $sName
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "MixerId", "REG_SZ", $sId)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "MixerName", "REG_SZ", $sName)
	GUICtrlSetData($idMixerId, $sId)
	GUICtrlSetData($idMixerName, $sName)
EndFunc

Func _SmashcastGetId()
	$sUsername = GUICtrlRead($idSmashcastInput)
	If $sUsername = "" Then Return _GetErrored()
	$sUsername = StringStripWS($sUsername, $STR_STRIPALL)
	$sQuotedUsername = URLEncode($sUsername)
	$sUserUrl = "https://api.smashcast.tv/user/" & $sQuotedUsername
	$iUserID = FetchItem($sUserUrl, "user_id")

	If IsKeyword($iUserID) <> $KEYWORD_NULL Then
		_SmashcastSet($iUserID, $sUsername)
	Else
		Return _GetErrored()
	EndIf
EndFunc

Func _SmashcastReset()
	_SmashcastSet("", "")
EndFunc

Func _SmashcastSet($sId, $sName)
	$sSmashcastId = $sId
	$sSmashcastName = $sName
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "SmashcastId", "REG_SZ", $sId)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "SmashcastName", "REG_SZ", $sName)
	GUICtrlSetData($idSmashcastId, $sId)
	GUICtrlSetData($idSmashcastName, $sName)
EndFunc

Func _GetErrored()
	MsgBox($MB_OK, @ScriptName, "ID not found, make sure you typed your username correctly and are connected to the internet", Default, $hGuiSettings)
EndFunc

Func _SettingsSaveAll()
	_SettingsRefresh()
	_SettingsUpdateCheck()
	_SettingsLog()
EndFunc

Func _SettingsHide()
	_SettingsSaveAll()
	GUISetState(@SW_HIDE, $hGuiSettings)
EndFunc
#EndRegion

#Region INTENRAL INTERLECT
;Based on https://stackoverflow.com/a/39651735 and "Install type" from Paint.NET
Func _InstallType()
	Local $APPMODEL_ERROR_NO_PACKAGE = 15700
	$hProcess = _WinAPI_OpenProcess($PROCESS_QUERY_LIMITED_INFORMATION, 0, @AutoItPID)
	If @error Then Return "Classical"
	$aResult = DllCall("Kernel32.dll", "LONG", "GetPackageFamilyName", "handle", $hProcess, "uint*", 0, "wstr", Null)
	$iError = @error
	_WinAPI_CloseHandle($hProcess)
	If $iError Then Return "Classical"
	If $aResult[0] = $APPMODEL_ERROR_NO_PACKAGE Then Return "Classical"
	Return "AppX"
EndFunc

Func _CW($sMessage)
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " " & $sMessage & @CRLF)

	If $sLog = 1 Then
		_DeleteOldLogs()

		Static Local $hLog = FileOpen(@ScriptDir & "\log" & @WDAY & ".txt", $FO_APPEND)
		If $hLog Then _FileWriteLog($hLog, $sMessage)
	EndIf
EndFunc

Func _DeleteOldLogs()
	Static Local $iRunOnce = False
	If $iRunOnce = True Then Return
	$iRunOnce = True

	$asLogs = _FileListToArray(@ScriptDir, "log*.txt", $FLTA_FILES, True)
	If @error Then Return
	Local $asLogsTime[$asLogs[0]][2]
	For $iX = 1 To $asLogs[0]
		$asLogsTime[$iX -1][0] = FileGetTime($asLogs[$iX], $FT_CREATED, $FT_STRING)
		$asLogsTime[$iX -1][1] = $asLogs[$iX]
	Next
	_ArraySort($asLogsTime, 1)   ;Sort newest first

	For $iX = 3 To UBound($asLogsTime) -1
		FileDelete($asLogsTime[$iX][1])
	Next

	_CW("Deleted old logs")
EndFunc

Func _StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $iService, $iUserID = "", $iFlags = $eIsStream)
	_CW("Found streamer: " & $sDisplayName)

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
	$aStreams[$iIndex][$eFlags] = $iFlags
	$aStreams[$iIndex][$eUserID] = $iUserID

	If Not IsArray($aStreams[$iIndex][$eQualities]) Then
;~ 		$aStreams[$iIndex][$eQualities] = _GetQualities($sUrl)
	EndIf
EndFunc

Func _CanHandleURL($sUrl)
	$iExitCode = RunWait("streamlink --can-handle-url " & $sUrl, "", @SW_HIDE)
	Return ($iExitCode = 0)
EndFunc

Func _GetQualities($sUrl)
	Local $asError[] = ["Error"]

	If $iStreamlinkInstalled = False Then Return $asError

	If Not _CanHandleURL($sUrl) Then Return $asError

	$iPID = Run("streamlink.exe --twitch-disable-hosting --json " & $sUrl, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)

	_CW(StringStripWS($sOutput, $STR_STRIPALL))

	$oJSON = Json_Decode($sOutput)
	If IsObj($oJSON) = False Then Return $asError

	$aoStreams = Json_ObjGet($oJSON, "streams")
	If IsObj($aoStreams) = False Then Return $asError

	Local $asQualities[0]
	For $vItem In $aoStreams
		If $vItem = "best" Or $vItem = "worst" Then ContinueLoop
		_ArrayAdd($asQualities, $vItem)
	Next

	_ArraySortNum($asQualities)
	Return $asQualities
EndFunc

;https://www.autoitscript.com/forum/topic/95383-sorting-numbers/?do=findComment&comment=685701
Func _ArraySortNum(ByRef $n_array, $i_descending = 0, $i_start = 0)
    Local $i_ub = UBound($n_array)
    For $i_count = $i_start To $i_ub - 2
        Local $i_se = $i_count
        If $i_descending Then
            For $x_count = $i_count To $i_ub - 1
                If Number($n_array[$i_se]) < Number($n_array[$x_count]) Then $i_se = $x_count
            Next
        Else
            For $x_count = $i_count To $i_ub - 1
                If Number($n_array[$i_se]) > Number($n_array[$x_count]) Then $i_se = $x_count
            Next
        EndIf
        Local $i_hld = $n_array[$i_count]
        $n_array[$i_count] = $n_array[$i_se]
        $n_array[$i_se] = $i_hld
    Next
EndFunc   ;==>_ArraySortNum

Func _PowerEvents($hWnd, $Msg, $wParam, $lParam)
	Switch $wParam
		Case $PBT_APMRESUMEAUTOMATIC
			AdlibUnRegister(_MAIN)
			AdlibRegister(_WaitForInternet)
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>_PowerEvents

Func _EndSessionEvents($hWnd, $iMsg, $wParam, $lParam)
	If $wParam = 1 Then Exit

	Return $GUI_RUNDEFMSG
EndFunc

Func _RemoteEvents($hWnd, $iMsg, $wParam, $lParam)
	AdlibRegister(_MAIN)

	;Don't bother with the internal message handler since it's my own message
	Return
EndFunc

Func _WaitForInternet()
	If _WinAPI_IsInternetConnected() Then
		AdlibUnRegister(_WaitForInternet)
		_MAIN()
	EndIf
EndFunc

Func _CheckUpdates()
	If $sInstallType = "AppX" Then Return

	_CW("Updateing")
	_ProgressSpecific("U")

	Switch $sUpdateCheck
		Case "Daily"
			If $sCheckTime = @YDAY Then Return
			RegWrite("HKCU\SOFTWARE\StreamHelper\", "CheckTime", "REG_SZ", @YDAY)
			$sCheckTime = @YDAY
		Case "Weekly"
			If $sCheckTime = _WeekNumberISO() Then Return
			RegWrite("HKCU\SOFTWARE\StreamHelper\", "CheckTime", "REG_SZ", _WeekNumberISO())
			$sCheckTime = _WeekNumberISO()
		Case "Monthly"
			If $sCheckTime = @MON Then Return
			RegWrite("HKCU\SOFTWARE\StreamHelper\", "CheckTime", "REG_SZ", @MON)
			$sCheckTime = @MON
		Case Else
			Return
	EndSwitch

	Local $dData = InetRead("https://api.github.com/repos/TzarAlkex/StreamHelper/releases/latest", $INET_FORCERELOAD)

	$sJson = BinaryToString($dData)
	_CW($sJson)

	$oJSON = Json_Decode($sJson)

	If IsObj($oJSON) = False Then Return _StreamSet("Update check failed", "", "", "", "", "", "", "", "", $eIsText)

	$sTag = Json_ObjGet($oJSON, "tag_name")

	$iInternalVersion = "v1.2"
	$iHigherVersion = _VersionCompare($sTag, $iInternalVersion)

	If @error Then
		_StreamSet("Update check failed", "", "", "", "", "", "", "", "", $eIsText)
	ElseIf $iHigherVersion = 1 Then
		$hTray = TrayItemGetHandle(0)
		$iCount = _GUICtrlMenu_GetItemCount($hTray)
		ReDim $aStreams[UBound($aStreams) +1][$eMax]
		$aStreams[UBound($aStreams) -1][$eDisplayName] = "Update found! Click to open website"
		$aStreams[UBound($aStreams) -1][$eUrl] = "https://github.com/TzarAlkex/StreamHelper/releases"
		$aStreams[UBound($aStreams) -1][$eTrayId] = TrayCreateItem("Update found! Click to open website", -1, $iCount -3)
		$aStreams[UBound($aStreams) -1][$eFlags] = $eIsLink
		TrayItemSetOnEvent( -1, _TrayStuff)
	EndIf
EndFunc
#EndRegion
