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

 AutoIt Version: 3.3.12.0 (Stable)
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

#ce ----------------------------------------------------------------------------

If (Not @Compiled) Then
	TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
EndIf

_UpgradeIni()

$sTwitchOAuth = IniRead(@ScriptDir & "\Settings.ini", "Section", "TwitchOAuth", "")   ;NAME ON TWITCHOAuth
If $sTwitchOAuth = "" Then $sTwitchUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Twitch", "")   ;NAME ON TWITCH
$sSmashcastUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Smashcast", "")   ;NAME ON SMASHCAST
$sMixerUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Mixer", "")   ;NAME ON MIXER
$iRefresh = IniRead(@ScriptDir & "\Settings.ini", "Section", "RefreshMinutes", 2) * 60000   ;HOW MANY TIME UNITS BETWEEN EVERY CHECK FOR NEW STREAMS
$iPrintJSON = IniRead(@ScriptDir & "\Settings.ini", "Section", "PrintJSON", "-1")   ;JUST TYPE SOMETHING TO CHECK
$sCheckForUpdates = "JustAlways Check probably"
$iClosePreviousBeforePlaying = True

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

TrayCreateItem("")
Local $idAbout = TrayCreateItem("About")
TrayItemSetOnEvent( -1, _TrayStuff)

Local $idExit = TrayCreateItem("Exit")
TrayItemSetOnEvent( -1, _TrayStuff)

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime, $eOnline, $eService, $eQualities, $eFlags, $eMax
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
Global $hGuiClipboard
Global $idLabel, $idQuality, $idPlay
Global $avDownloads[1][2]

If $iStreamlinkInstalled Then
	Local $iGuiWidth = 420, $iGuiHeight = 70

	If Random(0, 1, 1) Then
		$hGuiClipboard = GUICreate("To infinity... and beyond!", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	Else
		$hGuiClipboard = GUICreate("Copy Streamlink compatible link to clipboard", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	EndIf

	$idLabel = GUICtrlCreateLabel("I am word", 70, 10, 350, 20)
	$idQuality = GUICtrlCreateCombo("", 70, 40, 160, 20)
	$idPlay = GUICtrlCreateButton("Play", 240, 40, 80, 20)
	GUICtrlSetOnEvent(-1, _GuiPlay)
	$idDownload = GUICtrlCreateButton("Download", 330, 40, 80, 20)
	GUICtrlSetOnEvent(-1, _GuiDownload)
	$idUrl = GUICtrlCreateDummy()

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

#Region TWITCH OAuth
Func _TwitchOAuth()
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
	ConsoleWrite("Twitching (OAuth)" & @CRLF)
	_ProgressSpecific("T")

	_TwitchOAuthGet($sTwitchOAuth)

	$iTrayRefresh = True
EndFunc

Func _TwitchOAuthGet($sOAuth)
	$sUrl = "https://api.twitch.tv/kraken/streams/followed?oauth_token=" & $sOAuth & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"

	$oStreams = FetchItems($sUrl, "streams")
	If UBound($oStreams) = 0 Then Return

	For $iX = 0 To UBound($oStreams) -1
		$oChannel = Json_ObjGet($oStreams[$iX], "channel")

		$sUrl = Json_ObjGet($oChannel, "url")
		$sDisplayName = Json_ObjGet($oChannel, "display_name")
		$sGame = Json_ObjGet($oChannel, "game")

		Local $iFlags = $eIsStream
		If Json_ObjGet($oStreams[$iX], "stream_type") = "watch_party" Then $iFlags = BitOR($iFlags, $eVodCast)

		_StreamSet($sDisplayName, $sUrl, "", $sGame, "", "", "", $eTwitch, $iFlags)
	Next

	Static Local $sUserName = ""

	If $sUserName = "" Then
		$sUserUrl = "https://api.twitch.tv/kraken/user?oauth_token=" & $sOAuth & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"
		$sUserName = FetchItem($sUserUrl, "name")
		If $sUserName = "" Then Return
	EndIf

	_TwitchGetGames($sUsername)
EndFunc
#EndRegion

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

	Static Local $iUserID = ""

	If $iUserID = "" Then
		$sUserUrl = "https://api.twitch.tv/kraken/users?login=" & $sQuotedUsername & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"
		$oUser = FetchItems($sUserUrl, "users")
		$iUserID = Json_ObjGet($oUser[0], "_id")
		If $iUserID = "" Then Return
	EndIf

	Static Local $sBaseUrl = "https://api.twitch.tv/kraken/users/" & $iUserID & "/follows/channels"

	While True
		Local $sUrl = $sBaseUrl & OPTIONS_OFFSET_LIMIT_TWITCH($iOffset, $iLimit) & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"
		$avTemp = FetchItems($sUrl, "follows")
		If UBound($avTemp) = 0 Then ExitLoop

		Local $sOptions = ""
		For $iX = 0 To UBound($avTemp) -1
			$oChannel = Json_ObjGet($avTemp[$iX], "channel")
			$iId = Json_ObjGet($oChannel, "_id")
			$sOptions &= $iId & ','
		Next

		$sOptions = StringTrimRight($sOptions, 1)
		$sUrl = 'https://api.twitch.tv/kraken/streams?channel=' & $sOptions & '&limit=' & $iLimit & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"
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

			Local $iFlags = $eIsStream
			If Json_ObjGet($oChannel[$iX], "stream_type") = "watch_party" Then $iFlags = BitOR($iFlags, $eVodCast)

			_StreamSet($sDisplayName, $sUrl, $sMedium, $sGame, $sCreated, $sTime, $sStatus, $eTwitch, $iFlags)
		Next

		$iOffset += $iLimit
	WEnd

	_TwitchGetGames($sQuotedUsername)

	Return "Potato on a Stick"
EndFunc

Func _TwitchGetGames($sUsername)
	Local $sGamesUrl = "https://api.twitch.tv/api/users/" & $sUsername & "/follows/games/live?client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"

	$avTemp = FetchItems($sGamesUrl, "follows")
	If UBound($avTemp) = 0 Then Return

	For $iX = 0 To UBound($avTemp) -1
		$sName = Json_ObjGet($avTemp[$iX], "name")

		$sUrl = 'https://api.twitch.tv/kraken/streams/game=' & $sName & "&client_id=i8funp15gnh1lfy1uzr1231ef1dxg07&api_version=5"
		$oChannel = FetchItems($sUrl, "streams")

		For $iY = 0 To UBound($oChannel) -1
			$oChannel2 = Json_ObjGet($oChannel[$iY], "channel")
			$sUrl = Json_ObjGet($oChannel2, "url")
			If $sUrl = "" Then $sUrl = "http://www.twitch.tv/" & Json_ObjGet($oChannel2, "name")

			$sDisplayName = Json_ObjGet($oChannel2, "display_name")

			$sGame = Json_ObjGet($oChannel[$iY], "game")

			_StreamSet($sDisplayName, $sUrl, "", $sGame, "", "", "", $eTwitch)
		Next
	Next
EndFunc

Func OPTIONS_OFFSET_LIMIT_TWITCH($iOffset, $iLimit)
	Return '?offset=' & $iOffset & '&limit=' & $iLimit
EndFunc
#EndRegion TWITCH

#Region SMASHCAST
Func _Smashcast()
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
	ConsoleWrite("Smashcasting" & @CRLF)
	_ProgressSpecific("S")

	_SmashcastGet($sSmashcastUsername)

	$iTrayRefresh = True
EndFunc

Func _SmashcastGet($sUsername)
	$iLimit = 100
	$iOffset = 0
	Static Local $iUserID = ""

	If $iUserID = "" Then
		$sQuotedUsername = URLEncode($sUsername)

		$sUserUrl = "https://api.smashcast.tv/user/" & $sQuotedUsername
		$iUserID = FetchItem($sUserUrl, "user_id")
		If $iUserID = "" Then Return
	EndIf

	Local $sUrl = "https://api.smashcast.tv/media/live/list?follower_id=" & $iUserID
	$oLivestream = FetchItems($sUrl, "livestream")
	If UBound($oLivestream) = 0 Then Return

	For $iX = 0 To UBound($oLivestream) -1
		$oChannel = Json_ObjGet($oLivestream[$iX], "channel")
		$sUrl = Json_ObjGet($oChannel, "channel_link")

		$sDisplayName = Json_ObjGet($oLivestream[$iX], "media_display_name")

		$sStatus = Json_ObjGet($oLivestream[$iX], "media_status")

		;The website actually still says to use the hitbox url for images, prob a doc error but whatever
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

		_StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $eSmashcast)
	Next

	Return "Potato on a Stick"
EndFunc

Func OPTIONS_OFFSET_LIMIT_SMASHCAST($iOffset, $iLimit)
	Return '&offset=' & $iOffset & '&limit=' & $iLimit
EndFunc
#EndRegion

#Region MIXER
Func _Mixer()
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
	ConsoleWrite("Mixering" & @CRLF)
	_ProgressSpecific("M")

	_MixerGet($sMixerUsername)

	$iTrayRefresh = True
EndFunc

Func _MixerGet($sUsername)
	$iLimit = 100
	$iOffset = 0
	Static Local $iUserID = ""

	If $iUserID = "" Then
		$sQuotedUsername = URLEncode($sUsername)

		$sUserUrl = "https://mixer.com/api/v1/channels/" & $sQuotedUsername
		$iUserID = FetchItem($sUserUrl, "userId")
		If $iUserID = "" Then Return
	EndIf

	Local $sUrl = "https://mixer.com/api/v1/users/" & $iUserID & "/follows?where=online:eq:1"
	$oFollows = getJson($sUrl)
	If UBound($oFollows) = 0 Then Return

	For $iX = 0 To UBound($oFollows) -1
		$oUser = Json_ObjGet($oFollows[$iX], "user")
		$sDisplayName = Json_ObjGet($oUser, "username")

		$sUrl = "https://beam.pro/" & Json_ObjGet($oFollows[$iX], "token")   ;streamlink hasn't added mixer domain yet

		$oType = Json_ObjGet($oFollows[$iX], "type")
		If IsObj($oType) Then
			$sGame = Json_ObjGet($oType, "name")
		Else
			$sGame = "No game selected"
		EndIf

		_StreamSet($sDisplayName, $sUrl, "", $sGame, "", "", "", $eMixer)
	Next

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
	ConsoleWrite("myURL " & $sUrl & @CRLF)

	For $iX = 1 To 3
		$dJsonString = InetRead($sUrl, $INET_FORCERELOAD)
		If @error = 0 Then ExitLoop
	Next
	If @error Then ConsoleWrite("All downloads failed" & @CRLF)

	If $iPrintJSON <> "-1" Then
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
			If BitAND($aStreams[$iX][$eFlags], $eVodCast) Then $sDisplayName = "[v] " & $sDisplayName

			Local $sTrayText = $sDisplayName
			If $aStreams[$iX][$eGame] <> "" Then $sTrayText &= " | " & $aStreams[$iX][$eGame]

			$aStreams[$iX][$eOnline] = False

			If $aStreams[$iX][$eTrayId] = 0 Then
				$aStreams[$iX][$eTrayId] = TrayCreateItem($sTrayText, -1, 0)
				If StringLeft($sDisplayName, 4) <> "[i] " Then
					Local $NewText = $aStreams[$iX][$eDisplayName]
					If $aStreams[$iX][$eGame] <> "" And $bBlobFirstRun <> True Then $NewText &= " | " & $aStreams[$iX][$eGame]
					$sNew &= $NewText & @CRLF

					If StringLeft($sDisplayName, 4) = "[F] " Then $bFavoriteFound = True
				EndIf
				TrayItemSetOnEvent( -1, _TrayStuff)
			Else
				If $sTrayText = TrayItemGetText($aStreams[$iX][$eTrayId]) Then ContinueLoop

				TrayItemSetText($aStreams[$iX][$eTrayId], $sTrayText)

				Local $NewText = $aStreams[$iX][$eDisplayName]
				If $aStreams[$iX][$eGame] <> "" Then $NewText &= " | " & $aStreams[$iX][$eGame]
				$sChanged &= $NewText & @CRLF

				If StringLeft($sDisplayName, 4) = "[F] " Then $bFavoriteFound = True
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

			If BitAND($aStreams[$iX][$eFlags], $eIsLink) = $eIsLink Then
				ShellExecute($sUrl)
			ElseIf BitAND($aStreams[$iX][$eFlags], $eIsText) = $eIsText Then
				Return
			ElseIf BitAND($aStreams[$iX][$eFlags], $eIsStream) = $eIsStream Then
				If $iStreamlinkInstalled Then
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
						_StreamlinkPlay($sUrl)
					EndIf
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
	If $sCheckForUpdates <> "" Then _CheckUpdates()

	If $sTwitchOAuth <> "" Then
		_TwitchOAuth()
	ElseIf $sTwitchUsername <> "" Then
		_Twitch()
	EndIf
	If $sSmashcastUsername <> "" Then _Smashcast()
	If $sMixerUsername <> "" Then _Mixer()

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
			Local $iReplacedLength = StringLen($sReplaced)

			;Win 10 November Update seems to have a 140 character limit when just a block of text, but here spaces and things screw that up.
			;I'm guessing 120 is low enough to cover most situations.
			$sReplaced = StringLeft($sReplaced, 120)
			If StringLen($sReplaced) <> $iReplacedLength Then $sReplaced &= "..."
			TrayTip("Now streaming", $sReplaced, 10)
		ElseIf @OSBuild >= 10240 Then
			$asSplit = StringSplit($sNew, @CRLF, $STR_ENTIRESPLIT)
			For $iX = 1 To $asSplit[0]
				TrayTip("Now streaming", $asSplit[$iX], 10)
			Next

			$asSplit = StringSplit($sChanged, @CRLF, $STR_ENTIRESPLIT)
			For $iX = 1 To $asSplit[0]
				TrayTip("Changed game", $asSplit[$iX], 10)
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

	If $bFavoriteFound = True Then
		SoundPlay(@ScriptDir & "\Authentic A-10 Warthog sounds TM.wav")
		$bFavoriteFound = False
	EndIf

	AdlibRegister(_MAIN, $iRefresh)
EndFunc

Func _GuiPlay()
	Local $sQuality = GUICtrlRead($idQuality)
	Local $sUrl = GUICtrlRead($idUrl)

	_StreamlinkPlay($sUrl, $sQuality)
EndFunc

Func _GuiDownload()
	$sPathToFile = FileSaveDialog("Save Stream to", "", "Video files (*.mp4)")

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

Func _ClipboardGo($asStream)
	Local $sTitle
	Local $sUrl = $asStream[0]

	If UBound($asStream) > 1 Then $sTitle &= $asStream[1]
	GUICtrlSetData($idLabel, $sTitle)

	GUICtrlSetState($idQuality, $GUI_HIDE)

	_GUICtrlComboBox_ResetContent($idQuality)
	GUICtrlSendToDummy($idUrl, $sUrl)

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

#Region INTENRAL INTERLECT
Func _UpgradeIni()
	$sHitboxUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Hitbox", "")   ;NAME ON HITBOX
	If $sHitboxUsername <> "" Then
		IniWrite(@ScriptDir & "\Settings.ini", "Section", "Smashcast", $sHitboxUsername)
		IniDelete(@ScriptDir & "\Settings.ini", "Section", "Hitbox")
	EndIf

	$sBeamUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Beam", "")   ;NAME ON BEAM
	If $sBeamUsername <> "" Then
		IniWrite(@ScriptDir & "\Settings.ini", "Section", "Mixer", $sBeamUsername)
		IniDelete(@ScriptDir & "\Settings.ini", "Section", "Beam")
	EndIf

	IniDelete(@ScriptDir & "\Settings.ini", "Section", "CheckForUpdates")
EndFunc

Func _StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $iService, $iFlags = $eIsStream)
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
	$aStreams[$iIndex][$eFlags] = $iFlags

	If Not IsArray($aStreams[$iIndex][$eQualities]) Then
;~ 		$aStreams[$iIndex][$eQualities] = _GetQualities($sUrl)
	EndIf
EndFunc

Func _CanHandleURL($sUrl)
	$iExitCode = RunWait("streamlink --can-handle-url " & $sUrl, "", @SW_HIDE)
	Return ($iExitCode = 0)
EndFunc

Func _GetQualities($sUrl)
	If $iStreamlinkInstalled = False Then Return ""

	Local $asError[] = ["Error"]

	If Not _CanHandleURL($sUrl) Then Return $asError

	$iPID = Run("streamlink.exe --twitch-disable-hosting --json " & $sUrl, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)

	If $iPrintJSON <> "-1" Then
		ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
		ConsoleWrite(StringStripWS($sOutput, $STR_STRIPALL) & @CRLF)
	EndIf

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

Func _WaitForInternet()
	If _WinAPI_IsInternetConnected() Then
		AdlibUnRegister(_WaitForInternet)
		_MAIN()
	EndIf
EndFunc

Func _CheckUpdates()
	ConsoleWrite('"Updateing"' & @CRLF)
	_ProgressSpecific("U")
	$sCheckForUpdates = ""

	Local $dData = InetRead("https://api.github.com/repos/TzarAlkex/StreamHelper/releases/latest", $INET_FORCERELOAD)

	If $iPrintJSON <> "-1" Then
		ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " ")
		ConsoleWrite(BinaryToString($dData) & @CRLF)
	EndIf

	$oJSON = Json_Decode(BinaryToString($dData))

	If IsObj($oJSON) = False Then Return _StreamSet("Update check failed", "poopsicle", "", "", "", "", "", "", $eIsText)

	$sTag = Json_ObjGet($oJSON, "tag_name")

	$iInternalVersion = "v1.2"
	$iHigherVersion = _VersionCompare($sTag, $iInternalVersion)

	If @error Then
		_StreamSet("Update check failed", "poopsicle", "", "", "", "", "", "", $eIsText)
	ElseIf $iHigherVersion = 1 Then
		_StreamSet("Update found! Click to open website", "https://github.com/TzarAlkex/StreamHelper/releases", "", "", "", "", "", "", $eIsLink)
	EndIf
EndFunc
#EndRegion
