#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Svartnos.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=StreamHelper
#AutoIt3Wrapper_Res_Fileversion=1.2.0.0
#AutoIt3Wrapper_Res_ProductVersion=1.2.0.0
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

2017-10-25 19:13:25 : myURL users/follows?from_id=37714348&first=100&after=eyJiIjpudWxsLCJhIjoiMTQ1NDcwNjQ0OTY2OTg5MDAwMCJ9
2017-10-25 19:13:26 : HTTP/1.1 502 Bad Gateway \ Connection: keep-alive \ Date: Wed, 25 Oct 2017 17:13:26 GMT \ Content-Length: 138 \ Content-Type: text/html \ Server: awselb/2.0
2017-10-25 19:13:26 : <html>
<head><title>502 Bad Gateway</title></head>
<body bgcolor="white">
<center><h1>502 Bad Gateway</h1></center>
</body>
</html>

wtf fix!

*Notifications are not optimal (only 4 rows are seen, so if there's more than 4 streams you just don't see the extras)

*Check if AutoIt can use the appx protocol
ms-appx:///Relative/Path/To/Content.jpg

*Remake icon?
*Or redo in better quality (Square310x310Logo.scale-400.png is just a resized Square310x310Logo.scale-200.png)

#ce ----------------------------------------------------------------------------

#include <AutoItConstants.au3>
#include "Json.au3"
#include <Array.au3>
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
#include <String.au3>

If _Singleton("AutoIt window with hopefully a unique title|Ketchup the second", 1) = 0 Then
	$iWM = _WinAPI_RegisterWindowMessage("AutoIt window with hopefully a unique title|Ketchup the second")
	_WinAPI_PostMessage(WinGetHandle("AutoIt window with hopefully a unique title|Senap the third"), $iWM, 0, 0)
	Exit
EndIf

TraySetToolTip("StreamHelper")
If (Not @Compiled) Then
	TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
EndIf

$iClosePreviousBeforePlaying = True

$sLog = RegRead("HKCU\SOFTWARE\StreamHelper\", "Log")
_CW("Install type: " & _InstallType())

Global $sUpdateCheck
If _InstallType() = "AppX" Then
	$sUpdateCheck = "Never"
Else
	$sUpdateCheck = RegRead("HKCU\SOFTWARE\StreamHelper\", "UpdateCheck")
	If @error Then $sUpdateCheck = "Daily"
EndIf
$sCheckTime = RegRead("HKCU\SOFTWARE\StreamHelper\", "CheckTime")
If @error Then $sCheckTime = "0"
$sRefreshMinutes = RegRead("HKCU\SOFTWARE\StreamHelper\", "RefreshMinutes")
If @error Then $sRefreshMinutes = 3
$sIgnoreMinutes = RegRead("HKCU\SOFTWARE\StreamHelper\", "IgnoreMinutes")
If @error Then $sIgnoreMinutes = 0

Global $iSmashcastEnable = False, $iYoutubeEnable = False

$sTwitchId = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchId")
$sTwitchName = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchName")
$sMixerId = RegRead("HKCU\SOFTWARE\StreamHelper\", "MixerId")
$sMixerName = RegRead("HKCU\SOFTWARE\StreamHelper\", "MixerName")
If $iSmashcastEnable Then
	$sSmashcastId = RegRead("HKCU\SOFTWARE\StreamHelper\", "SmashcastId")
	$sSmashcastName = RegRead("HKCU\SOFTWARE\StreamHelper\", "SmashcastName")
EndIf
If $iYoutubeEnable Then
	$sYoutubeId = RegRead("HKCU\SOFTWARE\StreamHelper\", "YoutubeId")
	$sYoutubeName = RegRead("HKCU\SOFTWARE\StreamHelper\", "YoutubeName")
EndIf

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

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime, $eOnline, $eService, $eQualities, $eFlags, $eUserID, $eGameID, $eTimer, $eStreamID, $eOldStreamID, $eMax
Global Enum $eTwitch, $eSmashcast, $eMixer, $eYoutube
Global Enum Step *2 $eVodCast, $eIsLink, $eIsText, $eIsStream

Global Enum $iStartupTaskStateError = -1, $iStartupTaskStateDisabled, $iStartupTaskStateDisabledByUser, $iStartupTaskStateEnabled, $iStartupTaskStateDisabledByPolicy, $iStartupTaskStateEnabledByPolicy

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
Global $idRefreshMinutes, $idIgnoreMinutes, $idUpdates, $idStartup, $idStartupTooltip, $idStartupLegacy, $idLog, $idTwitchInput, $idTwitchId, $idTwitchName, $idMixerInput, $idMixerId, $idMixerName, $idSmashcastInput, $idSmashcastId, $idSmashcastName, $idYoutubeInput, $idYoutubeId, $idYoutubeName
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

_WinAPI_RegisterApplicationRestart($RESTART_NO_CRASH)

While 1
	Sleep(3600000)
WEnd

#Region TWITCH
Func _TwitchNew()
	_CW("Twitching")
	_ProgressSpecific("T")

	_TwitchGet()

	_TwitchGetGames()

	_TwitchProcessUserID()
	_TwitchProcessGameID()

	$iTrayRefresh = True
EndFunc

Func _TwitchGet()
	$sCursor = ""

	While True
		$sUrl = "users/follows?from_id=" & $sTwitchId & "&first=100&after=" & $sCursor
		$oJSON = _TwitchFetch($sUrl)
		If IsObj($oJSON) = False Then Return

		$aData = Json_ObjGet($oJSON, "data")
		If UBound($aData) = 0 Then ExitLoop

		$oPagination = Json_ObjGet($oJSON, "pagination")
		$sCursor = Json_ObjGet($oPagination, "cursor")

		Local $sUsers = ""
		For $iX = 0 To UBound($aData) -1
			$sUser = Json_ObjGet($aData[$iX], "to_id")
			$sUsers &= "&user_id=" & $sUser
		Next
		$sUsers = StringTrimLeft($sUsers, 1)

		$sUrl = "streams?" & $sUsers & "&first=100"
		$oJSON = _TwitchFetch($sUrl)
		If IsObj($oJSON) = False Then Return

		$aData2 = Json_ObjGet($oJSON, "data")
		If UBound($aData2) = 0 Then
			If UBound($aData) <> 100 Then Return "Potato on a Stick"
			ContinueLoop
		EndIf

		For $iX = 0 To UBound($aData2) -1
			$sStreamID = Json_ObjGet($aData2[$iX], "id")
			$sUserID = "T" & Json_ObjGet($aData2[$iX], "user_id")
			$sGameID = Json_ObjGet($aData2[$iX], "game_id")

			Local $iFlags = $eIsStream
			If Json_ObjGet($aData2[$iX], "type") = "vodcast" Then $iFlags = BitOR($iFlags, $eVodCast)

			_StreamSet("", "", "", "", "", "", "", $eTwitch, $sUserID, $sStreamID, $iFlags, $sGameID)
		Next
		If UBound($aData) <> 100 Then Return "Potato on a Stick"
	WEnd

	Return "Potato on a Stick"
EndFunc

Func _TwitchGetGames()
	$sUrl = "users?id=" & $sTwitchId
	$oJSON = _TwitchFetch($sUrl)
	If IsObj($oJSON) = False Then Return

	$aData = Json_ObjGet($oJSON, "data")
	If UBound($aData) <> 1 Then Return

	$sUserName = Json_ObjGet($aData[0], "login")
	If $sUserName = "" Then
		Return
	ElseIf $sUserName <> $sTwitchName Then
		RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchName", "REG_SZ", $sUsername)
		$sTwitchName = $sUsername
	EndIf

	$oJSON = _WinHttpFetch("api.twitch.tv", "api/users/" & $sUsername & "/follows/games/live", "Client-ID: " & "i8funp15gnh1lfy1uzr1231ef1dxg07")
	If IsObj($oJSON) = False Then Return

	$avTemp = Json_ObjGet($oJSON, "follows")
	If UBound($avTemp) = 0 Then Return

	For $iX = 0 To UBound($avTemp) -1
		$oGame = Json_ObjGet($avTemp[$iX], "game")
		$sName = Json_ObjGet($oGame, "name")

		$oJSON = _WinHttpFetch("api.twitch.tv", "kraken/streams/?game=" & $sName, "Client-ID: " & "i8funp15gnh1lfy1uzr1231ef1dxg07")
		If IsObj($oJSON) = False Then Return

		$oStreams = Json_ObjGet($oJSON, "streams")

		For $iY = 0 To UBound($oStreams) -1
			$sStreamID = Json_ObjGet($oStreams[$iY], "_id")

			$oChannel = Json_ObjGet($oStreams[$iY], "channel")
			$sUrl = Json_ObjGet($oChannel, "url")
			$sName = Json_ObjGet($oChannel, "display_name")
			If StringIsASCII($sName) = 0 Then $sName = Json_ObjGet($oChannel, "name")
			$sGame = Json_ObjGet($oChannel, "game")
			$sUserID = "T" & Json_ObjGet($oChannel, "_id")

			_StreamSet($sName, $sUrl, "", $sGame, "", "", "", $eTwitch, $sUserID, $sStreamID)
		Next
	Next
EndFunc

Func _TwitchProcessUserID()
	Local $sUsers = "", $iCount = 0
	For $iX = 0 To UBound($aStreams) -1
		If $aStreams[$iX][$eService] <> $eTwitch Then ContinueLoop
		If $aStreams[$iX][$eDisplayName] <> "" And $aStreams[$iX][$eUrl] <> "" Then ContinueLoop

		$sUsers &= "&id=" & StringTrimLeft($aStreams[$iX][$eUserID], 1)
		$iCount += 1
		If $iCount = 100 Then ExitLoop
	Next
	$sUsers = StringTrimLeft($sUsers, 1)

	If $iCount = 0 Then Return

	$sUrl = "users?" & $sUsers
	$oJSON = _TwitchFetch($sUrl)
	If IsObj($oJSON) = False Then Return

	$aData = Json_ObjGet($oJSON, "data")
	If UBound($aData) = 0 Then Return

	For $iX = 0 To UBound($aData) -1
		$sDisplayName = Json_ObjGet($aData[$iX], "display_name")
		$sLogin = Json_ObjGet($aData[$iX], "login")
		$sID = Json_ObjGet($aData[$iX], "id")
		If StringIsASCII($sDisplayName) = 0 Then $sDisplayName = $sLogin
		$sUrl = "https://www.twitch.tv/" & $sLogin

		For $iIndex = 0 To UBound($aStreams) -1
			If $aStreams[$iIndex][$eUserID] = "T" & $sID Then
				$aStreams[$iIndex][$eDisplayName] = $sDisplayName
				$aStreams[$iIndex][$eUrl] = $sUrl

				ExitLoop
			EndIf
		Next
	Next
EndFunc

Func _TwitchProcessGameID()
	Local $sGames = "", $iCount = 0
	For $iX = 0 To UBound($aStreams) -1
		If $aStreams[$iX][$eService] <> $eTwitch Then ContinueLoop
		If $aStreams[$iX][$eGame] <> "" Then ContinueLoop

		If $aStreams[$iX][$eGameID] == "" Then
			$aStreams[$iX][$eGame] = "No game selected"
			ContinueLoop
		EndIf

		For $iIndex = 0 To UBound($aStreams) -1
			If $aStreams[$iIndex][$eGameID] == $aStreams[$iX][$eGameID] And $aStreams[$iIndex][$eGame] <> "" Then
				$aStreams[$iX][$eGame] = $aStreams[$iIndex][$eGame]
				ContinueLoop 2
			EndIf
		Next

		$sGames &= "&id=" & $aStreams[$iX][$eGameID]
		$iCount += 1
		If $iCount = 100 Then ExitLoop
	Next
	$sGames = StringTrimLeft($sGames, 1)

	If $iCount = 0 Then Return

	$sUrl = "games?" & $sGames
	$oJSON = _TwitchFetch($sUrl)
	If IsObj($oJSON) = False Then Return

	$aData = Json_ObjGet($oJSON, "data")
	If UBound($aData) = 0 Then Return

	For $iX = 0 To UBound($aData) -1
		$sGame = Json_ObjGet($aData[$iX], "name")
		$sID = Json_ObjGet($aData[$iX], "id")

		For $iIndex = 0 To UBound($aStreams) -1
			If $aStreams[$iIndex][$eGameID] = $sID Then
				$aStreams[$iIndex][$eGame] = $sGame
			EndIf
		Next
	Next
EndFunc

Func _TwitchFetch($sUrl)
	Return _WinHttpFetch("api.twitch.tv", "helix/" & $sUrl, "Client-ID: " & "i8funp15gnh1lfy1uzr1231ef1dxg07")
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
		Local $sUrl = "media/live/list?follower_id=" & $sSmashcastId & "&start=" & $iOffset
		$oJSON = _SmashcastFetch($sUrl)
		If IsObj($oJSON) = False Then Return

		$oLivestream = Json_ObjGet($oJSON, "livestream")
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

			$sStreamID = Json_ObjGet($oLivestream[$iX], "media_id")

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

			_StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $eSmashcast, $sUserID, $sStreamID)
		Next
		If UBound($oLivestream) <> 100 Then Return "Potato on a Stick"
		$iOffset += 100
	WEnd

	Return "Potato on a Stick"
EndFunc

Func _SmashcastFetch($sUrl)
	Return _WinHttpFetch("api.smashcast.tv", $sUrl)
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
		Local $sUrl = "users/" & $sMixerId & "/follows?page=" & $iOffset & "&limit=100&where=online:eq:1&fields=user,token,type&noCount=1"
		$oFollows = _MixerFetch($sUrl)
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

Func _MixerFetch($sUrl)
	Return _WinHttpFetch("mixer.com", "api/v1/" & $sUrl)
EndFunc
#EndRegion

#Region YOUTUBE
Func _Youtube()
	_CW("Youtubeing")
	_ProgressSpecific("Y")

	_YoutubeGet()

	$iTrayRefresh = True
EndFunc

Func _YoutubeGet()
	Local $sPageToken = ""

	While 1
		Local $sUrl = "subscriptions?part=snippet&channelId=" & $sYoutubeId & "&maxResults=50&pageToken=" & $sPageToken & "&fields=items%2Fsnippet%2FresourceId%2FchannelId%2CnextPageToken"
		$oChannels = _YoutubeFetch($sUrl)
		If IsObj($oChannels) = False Then Return
		$aItems = Json_ObjGet($oChannels, "items")
		If UBound($aItems) = 0 Then Return

		$sPageToken = Json_ObjGet($oChannels, "nextPageToken")

		For $iX = 0 To UBound($aItems) -1
			$oSnippet = Json_ObjGet($aItems[$iX], "snippet")
			$oResourceId = Json_ObjGet($oSnippet, "resourceId")
			$sChannelId = Json_ObjGet($oResourceId, "channelId")
			$sUserID = "Y" & $sChannelId

			$sUrl = "search?part=snippet&channelId=" & $sChannelId & "&eventType=live&type=video&fields=items(id%2FvideoId%2Csnippet(channelTitle%2Ctitle))"
			$oChannels = _YoutubeFetch($sUrl)
			If IsObj($oChannels) = False Then ContinueLoop
			$aItem = Json_ObjGet($oChannels, "items")
			If UBound($aItem) = 0 Then ContinueLoop

			$oID = Json_ObjGet($aItem[0], "id")
			$sUrl = "https://www.youtube.com/watch?v=" & Json_ObjGet($oID, "videoId")

			$oSnippet = Json_ObjGet($aItem[0], "snippet")
			$sGame = Json_ObjGet($oSnippet, "title")
			$sDisplayName = Json_ObjGet($oSnippet, "channelTitle")

			_StreamSet($sDisplayName, $sUrl, "", $sGame, "", "", "", $eYoutube, $sUserID)
		Next

		If $sPageToken = "" Then ExitLoop
	WEnd

	Return "Potato on a Stick"
EndFunc

Func _YoutubeFetch($sUrl)
	Static Local $vCache[0][2]
	Local $vRet = _WinHttpFetch("www.googleapis.com", "youtube/v3/" & $sUrl & "&key={YOUR_API_KEY}", Default, 2)
	Local $oJSON = $vRet[0]
	Local $sHeader = $vRet[1]
	Local $sETag = _StringBetween($sHeader, 'ETag: "', '"')
	Local $vToCache[1][2] = [[$sETag[0], $oJSON]]
	_ArrayAdd($vCache, $vToCache)
	Return $oJSON
EndFunc
#EndRegion

#Region COMMON
Func _WinHttpFetch($sDomain, $sUrl, $sHeader = Default, $sReturnFormat = Default)
	_CW("_WinHttpFetch: " & $sDomain & "/" & $sUrl & " \ " & $sHeader)

	Local $iTries = 0
	Do
		Sleep($iTries * 6000)

		Local $hOpen = _WinHttpOpen()
		Local $hConnect = _WinHttpConnect($hOpen, $sDomain)

		$asResponse = _WinHttpSimpleSSLRequest($hConnect, Default, $sUrl, Default, Default, $sHeader, True)

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)

		$iTries += 1
	Until (IsArray($asResponse) And StringSplit($asResponse[0], " ")[2] = 200) Or $iTries = 6

	If $asResponse = 0 Then
		_CW("_WinHttpFetch failed")
		Return
	EndIf

	_CW("Succeeded/failed after " & $iTries & " tries")
	_CW(StringReplace(StringStripWS($asResponse[0], $STR_STRIPTRAILING), @CRLF, " \ "))
	_CW($asResponse[1])

	$oJSON = Json_Decode($asResponse[1])

	If $sReturnFormat = Default Then
		Return $oJSON
	Else
		Local $vRet[2] = [$oJSON, $asResponse[0]]
		Return $vRet
	EndIf
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

			$sTrayText = StringReplace($sTrayText, "&", "&&")

			$aStreams[$iX][$eOnline] = False

			If $aStreams[$iX][$eTrayId] = 0 Then
				$aStreams[$iX][$eTrayId] = TrayCreateItem($sTrayText, -1, 0)
				If $aStreams[$iX][$eFlags] = $eIsStream And StringInStr($sDisplayName, "[i] ", $STR_CASESENSE, 1, 1, 8) = 0 And StringInStr($sDisplayName, "[v] ", $STR_CASESENSE, 1, 1, 8) = 0 Then
					Local $NewText = $aStreams[$iX][$eDisplayName]
					If $aStreams[$iX][$eGame] <> "" And $bBlobFirstRun <> True Then $NewText &= " | " & $aStreams[$iX][$eGame]

					If $aStreams[$iX][$eStreamID] = 404 Or $aStreams[$iX][$eStreamID] <> $aStreams[$iX][$eOldStreamID] Then
						$aStreams[$iX][$eOldStreamID] = $aStreams[$iX][$eStreamID]

						If $sIgnoreMinutes = 0 Or TimerDiff($aStreams[$iX][$eTimer]) * 1000 * 60 > $sIgnoreMinutes Then
							$aStreams[$iX][$eTimer] = TimerInit()

							$sNew &= $NewText & @CRLF
							If StringInStr($sDisplayName, "[F] ", $STR_CASESENSE, 1, 1, 8) Then $bFavoriteFound = True
						EndIf
					EndIf
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

	Global $sNew = "", $sChanged = ""
	_CheckUpdates()

	If $sTwitchId <> "" Then _TwitchNew()
	If $sMixerId <> "" Then _Mixer()
	If $iSmashcastEnable And $sSmashcastId <> "" Then _Smashcast()
	If $iYoutubeEnable And $sYoutubeId <> "" Then _Youtube()

	_CW("Getters done")
	_TrayRefresh()

	;https://www.autoitscript.com/forum/topic/146955-solved-remove-crlf-at-the-end-of-text-file/?do=findComment&comment=1041088
	If StringRight($sNew, 2) = @CRLF Then $sNew = StringTrimRight($sNew, 2)
	If StringRight($sChanged, 2) = @CRLF Then $sChanged = StringTrimRight($sChanged, 2)
	If (Not @Compiled) Then
		TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
	Else
		TraySetIcon()
	EndIf

	_CW("New streamer: " & StringReplace($sNew, @CRLF, ", "))
	_CW("Streamer changed game: " & StringReplace($sChanged, @CRLF, ", "))

	If $bFavoriteFound = True Then
		SoundPlay(@ScriptDir & "\Authentic A-10 Warthog sounds TM.wav")
		$bFavoriteFound = False
	EndIf

	If $sChanged <> "" Then
		If @OSBuild >= 10240 Then
			_TrayTipThis5($sChanged, "Changed game")
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
			_TrayTipThis5($sNew, "Now streaming")
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

Func _TrayTipThis4($sPeople, $iLines = 1)
	$asSplit = StringSplit($sPeople, @CRLF, $STR_ENTIRESPLIT)

	For $iX = 1 To $asSplit[0] Step $iLines
		Local $sText = ""
		If $iLines > 1 Then
			$sText &= $asSplit[$iX] & @CRLF
			If $iX <> $asSplit[0] Then $sText &= $asSplit[$iX+1] & @CRLF
		Else
			$sText &= $asSplit[$iX] & @CRLF
		EndIf
		$sText = StringTrimRight($sText, 2)
		If $asSplit[0] - $iX - ($iLines - 1) <= 0 Then
			TrayTip("Now streaming", $sText, 10)
		Else
			TrayTip("Now streaming (" & $asSplit[0] - $iX - ($iLines - 1) & " more)", $sText, 10)
		EndIf
	Next
EndFunc

Func _TrayTipThis5($sPeople, $sText)
	$asSplit = StringSplit($sPeople, @CRLF, $STR_ENTIRESPLIT)

	For $iX = $asSplit[0] To 1 Step -1
		Local $sName = $asSplit[$iX]
		If $iX = 1 Then
			TrayTip($sText, $sName, 10)
		Else
			TrayTip($sText & " (" & $iX -1 & " more)", $sName, 10)
		EndIf
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
	GUICtrlSetLimit(-1, 120, 3)

	GUICtrlCreateLabel("Minutes to ignore repeat notifications", 155, 40)
	$idIgnoreMinutes = GUICtrlCreateInput($sIgnoreMinutes, 155, 60, 80)
	GUICtrlCreateUpdown(-1, $UDS_ARROWKEYS)
	GUICtrlSetLimit(-1, 120, 3)

	If _InstallType() <> "AppX" Then
		GUICtrlCreateLabel("Check for updates", 20, 90)
		$idUpdates = GUICtrlCreateCombo("", 20, 110, 80)
		GUICtrlSetData(-1, "Never|Daily|Weekly|Monthly", $sUpdateCheck)
		GUICtrlCreateButton("Check now", 110, 110)
		GUICtrlSetOnEvent(-1, _CheckNow)
	EndIf

	If _InstallType() = "AppX" Then
		$iStatus = RunWait(@ScriptDir & "\CentennialStartupHelper.exe /status", @ScriptDir)
		If $iStatus <> $iStartupTaskStateError Then
			$idStartup = GUICtrlCreateCheckbox("Start automatically on user login", 20, 140)
			GUICtrlSetOnEvent(-1, _CentennialStartupSet)
			$aiPos = ControlGetPos($hGuiSettings, "", $idStartup)
			$idStartupTooltip = GUICtrlCreateLabel("", $aiPos[0], $aiPos[1], $aiPos[2], $aiPos[3])

			_CentennialStartupStatus($iStatus)
		EndIf
	Else
		$idStartupLegacy = GUICtrlCreateCheckbox("Start automatically on user login", 20, 140)
		GUICtrlSetOnEvent(-1, _LegacyStartupSet)
		If FileExists(@StartupDir & "\StreamHelper.lnk") Then GUICtrlSetState(-1, $GUI_CHECKED)
		If @Compiled = 0 Then GUICtrlSetState(-1, $GUI_DISABLE)
	EndIf

	$idLog = GUICtrlCreateCheckbox("Save log to file (don't enable unless asked)", 20, 170)
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

	If $iSmashcastEnable Then
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
	EndIf

	If $iYoutubeEnable Then
		GUICtrlCreateTabItem("Youtube")
		GUICtrlCreateLabel("1. Input username" & @CRLF & "2. Click Get ID", 20, 40)

		GUICtrlCreateLabel(" ", 20, 70)
		$idYoutubeInput = GUICtrlCreateInput("", 20, 90, 190)
		_GUICtrlEdit_SetCueBanner($idYoutubeInput, "Username")
		GUICtrlCreateButton("Get ID", 20, 120)
		GUICtrlSetOnEvent(-1, _YoutubeGetId)
		GUICtrlCreateButton("Reset", 155, 120)
		GUICtrlSetOnEvent(-1, _YoutubeReset)

		GUICtrlCreateLabel("Saved ID", 20, 160)
		$idYoutubeId = GUICtrlCreateInput($sYoutubeId, 20, 180, 120, Default, $ES_READONLY)
		GUICtrlCreateLabel("Saved Username", 155, 160)
		$idYoutubeName = GUICtrlCreateInput($sYoutubeName, 155, 180, 120, Default, $ES_READONLY)
	EndIf

	GUICtrlCreateTabItem("")

	GUISetOnEvent($GUI_EVENT_CLOSE, _SettingsHide)
EndFunc

Func _SettingsRefresh()
	Local $sNew = GUICtrlRead($idRefreshMinutes)
	If $sNew = $sRefreshMinutes Then Return
	$sRefreshMinutes = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "RefreshMinutes", "REG_SZ", $sRefreshMinutes)
EndFunc

Func _SettingsIgnore()
	Local $sNew = GUICtrlRead($idIgnoreMinutes)
	If $sNew = $sIgnoreMinutes Then Return
	$sIgnoreMinutes = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "IgnoreMinutes", "REG_SZ", $sIgnoreMinutes)
EndFunc

Func _CheckNow()
	_CheckUpdates(True)
	If (Not @Compiled) Then
		TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
	Else
		TraySetIcon()
	EndIf
EndFunc

Func _SettingsUpdateCheck()
	Local $sNew = GUICtrlRead($idUpdates)
	If $sNew = $sUpdateCheck Then Return
	$sUpdateCheck = $sNew
	$sCheckTime = 0
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "UpdateCheck", "REG_SZ", $sUpdateCheck)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "CheckTime", "REG_SZ", 0)
EndFunc

Func _CentennialStartupSet()
	Local $iChecked = BitAND(GUICtrlRead($idStartup), $GUI_CHECKED)

	Local $iStatus
	If $iChecked Then
		$iStatus = RunWait(@ScriptDir & "\CentennialStartupHelper.exe /enable", @ScriptDir)
	Else
		$iStatus = RunWait(@ScriptDir & "\CentennialStartupHelper.exe /disable", @ScriptDir)
	EndIf
	_CentennialStartupStatus($iStatus)
EndFunc

Func _CentennialStartupStatus($iStatus)
	If $iStatus = $iStartupTaskStateError Then
		GUICtrlSetState($idStartup, $GUI_INDETERMINATE)
		GUICtrlSetTip($idStartupTooltip, "Error?")
	ElseIf $iStatus = $iStartupTaskStateDisabled Then
		GUICtrlSetState($idStartup, $GUI_UNCHECKED)
		GUICtrlSetTip($idStartupTooltip, "")
	ElseIf $iStatus = $iStartupTaskStateDisabledByUser Then
		GUICtrlSetState($idStartup, $GUI_DISABLE)
		GUICtrlSetTip($idStartupTooltip, "Can't set autostart if disabled from Task Manager. Enable from there first.")
	ElseIf $iStatus = $iStartupTaskStateEnabled Then
		GUICtrlSetState($idStartup, $GUI_CHECKED)
		GUICtrlSetTip($idStartupTooltip, "")
	ElseIf $iStatus = $iStartupTaskStateDisabledByPolicy Then
		GUICtrlSetState($idStartup, $GUI_DISABLE)
		GUICtrlSetTip($idStartupTooltip, "The task is disabled by the administrator or group policy.")
	ElseIf $iStatus = $iStartupTaskStateEnabledByPolicy Then
		GUICtrlSetState($idStartup, $GUI_DISABLE)
		GUICtrlSetTip($idStartupTooltip, "The task is enabled by the administrator or group policy.")
	EndIf
EndFunc

Func _LegacyStartupSet()
	Local $iChecked = BitAND(GUICtrlRead($idStartupLegacy), $GUI_CHECKED)

	If $iChecked Then
		FileCreateShortcut(@AutoItExe, @StartupDir & "\StreamHelper.lnk")
	Else
		FileDelete(@StartupDir & "\StreamHelper.lnk")
	EndIf
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

	$oJSON = _TwitchFetch("users?login=" & $sQuotedUsername)
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

	$oJSON = _MixerFetch("channels/" & $sQuotedUsername)
	If IsObj($oJSON) = False Then Return _GetErrored()
	$iUserID = Json_ObjGet($oJSON, "userId")

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

	$oJSON = _SmashcastFetch("user/" & $sQuotedUsername)
	If IsObj($oJSON) = False Then Return _GetErrored()
	$iUserID = Json_ObjGet($oJSON, "user_id")

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

Func _YoutubeGetId()
	$sUsername = GUICtrlRead($idYoutubeInput)
	If $sUsername = "" Then Return _GetErrored()
	$sUsername = StringStripWS($sUsername, $STR_STRIPALL)
	$sQuotedUsername = URLEncode($sUsername)

	Switch True
		Case True
			$oJSON = _YoutubeFetch("channels?part=snippet&forUsername=" & $sQuotedUsername & "&fields=items(id%2Csnippet%2Ftitle)")
			If IsObj($oJSON) = False Then ContinueCase
			$aItems = Json_ObjGet($oJSON, "items")
			If UBound($aItems) <> 1 Then ContinueCase

			$sID = Json_ObjGet($aItems[0], "id")
			$oSnippet = Json_ObjGet($aItems[0], "snippet")
			$sUsername = Json_ObjGet($oSnippet, "title")
		Case False
			$oJSON = _YoutubeFetch("channels?part=snippet&id=" & $sQuotedUsername & "&fields=items(id%2Csnippet%2Ftitle)")
			If IsObj($oJSON) = False Then Return _GetErrored()
			$aItems = Json_ObjGet($oJSON, "items")
			If UBound($aItems) <> 1 Then Return _GetErrored()

			$sID = Json_ObjGet($aItems[0], "id")
			$oSnippet = Json_ObjGet($aItems[0], "snippet")
			$sUsername = Json_ObjGet($oSnippet, "title")
	EndSwitch

	If $sID <> "" Then
		_YoutubeSet($sID, $sUsername)
	Else
		Return _GetErrored()
	EndIf
EndFunc

Func _YoutubeReset()
	_YoutubeSet("", "")
EndFunc

Func _YoutubeSet($sId, $sName)
	$sYoutubeId = $sId
	$sYoutubeName = $sName
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "YoutubeId", "REG_SZ", $sId)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "YoutubeName", "REG_SZ", $sName)
	GUICtrlSetData($idYoutubeId, $sId)
	GUICtrlSetData($idYoutubeName, $sName)
EndFunc

Func _GetErrored()
	MsgBox($MB_OK, @ScriptName, "ID not found, make sure you typed your username correctly and are connected to the internet", Default, $hGuiSettings)
EndFunc

Func _SettingsSaveAll()
	_SettingsRefresh()
	_SettingsIgnore()
	_SettingsUpdateCheck()
	_SettingsLog()
EndFunc

Func _SettingsHide()
	_SettingsSaveAll()
	GUISetState(@SW_HIDE, $hGuiSettings)
EndFunc
#EndRegion

#Region INTENRAL INTERLECT
Func _InstallType()
	Static Local $sInstallType = _InstallTypeEx()
	Return $sInstallType
EndFunc

;Based on https://stackoverflow.com/a/39651735 and "Install type" from Paint.NET
Func _InstallTypeEx()
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

		Static Local $hLog = FileOpen(@LocalAppDataDir & "\StreamHelper\logs\log" & @WDAY & ".txt", $FO_APPEND + $FO_CREATEPATH)
		If $hLog Then _FileWriteLog($hLog, $sMessage)
	EndIf
EndFunc

Func _DeleteOldLogs()
	Static Local $iRunOnce = False
	If $iRunOnce = True Then Return
	$iRunOnce = True

	$asLogs = _FileListToArray(@LocalAppDataDir & "\StreamHelper\logs", "log*.txt", $FLTA_FILES, True)
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

Func _StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $iService, $iUserID, $sStreamID = 404, $iFlags = $eIsStream, $iGameID = "")
	If $sDisplayName <> "" Then
		_CW("Found streamer: " & $sDisplayName)
	Else
		_CW("Found id: " & $iUserID)
	EndIf

	For $iIndex = 0 To UBound($aStreams) -1
		If $aStreams[$iIndex][$eUserID] = $iUserID Then ExitLoop
	Next
	If $iIndex = UBound($aStreams) Then
		ReDim $aStreams[$iIndex +1][$eMax]
	EndIf

	If $iService = $eTwitch Then
		If $aStreams[$iIndex][$eGameID] <> $iGameID Then
			$aStreams[$iIndex][$eGame] = ""
		EndIf
	EndIf

	If $sDisplayName <> "" Then $aStreams[$iIndex][$eDisplayName] = $sDisplayName
	If $sUrl <> "" Then $aStreams[$iIndex][$eUrl] = $sUrl
	If $sGame <> "" Then $aStreams[$iIndex][$eGame] = $sGame
	$aStreams[$iIndex][$ePreview] = $sThumbnail
	$aStreams[$iIndex][$eCreated] = $sCreated
	$aStreams[$iIndex][$eTime] = $sTime
	$aStreams[$iIndex][$eStatus] = $sStatus
	$aStreams[$iIndex][$eOnline] = True
	$aStreams[$iIndex][$eService] = $iService
	$aStreams[$iIndex][$eFlags] = $iFlags
	$aStreams[$iIndex][$eUserID] = $iUserID
	$aStreams[$iIndex][$eGameID] = $iGameID
	$aStreams[$iIndex][$eStreamID] = $sStreamID

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

Func _OtherSet($sText, $iFlags, $sUrl = "")
	$hTray = TrayItemGetHandle(0)
	$iCount = _GUICtrlMenu_GetItemCount($hTray)
	ReDim $aStreams[UBound($aStreams) +1][$eMax]
	$aStreams[UBound($aStreams) -1][$eDisplayName] = $sText
	$aStreams[UBound($aStreams) -1][$eTrayId] = TrayCreateItem($sText, -1, $iCount -3)
	$aStreams[UBound($aStreams) -1][$eFlags] = $iFlags
	If $sUrl <> "" Then $aStreams[UBound($aStreams) -1][$eUrl] = $sUrl
EndFunc

Func _ShouldSkipUpdate($sUpdateCheck, $iTime)
	If $sCheckTime = $iTime Then
		_CW("Skipping because the " & $sUpdateCheck & " update check has already been run")
		Return 1
	EndIf
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "CheckTime", "REG_SZ", $iTime)
	$sCheckTime = $iTime
EndFunc

Func _CheckUpdates($iForce = False)
	If _InstallType() = "AppX" Then Return

	_CW("Updateing")
	_ProgressSpecific("U")

	If (Not $iForce) Then
		Switch $sUpdateCheck
			Case "Daily"
				If _ShouldSkipUpdate($sUpdateCheck, @YDAY) Then Return
			Case "Weekly"
				If _ShouldSkipUpdate($sUpdateCheck, _WeekNumberISO()) Then Return
			Case "Monthly"
				If _ShouldSkipUpdate($sUpdateCheck, @MON) Then Return
			Case Else
				Return
		EndSwitch
	EndIf

	$oJSON = _WinHttpFetch("api.github.com", "repos/TzarAlkex/StreamHelper/releases/latest")

	If IsObj($oJSON) = False Then
		_OtherSet("Update check failed", $eIsText)
		Return
	EndIf

	$sTag = Json_ObjGet($oJSON, "tag_name")

	$iInternalVersion = "1.2.0.0"

	If $iInternalVersion <> $sTag Then
		_OtherSet("Update found! Click to open website", $eIsLink, "https://github.com/TzarAlkex/StreamHelper/releases")
		TrayItemSetOnEvent(-1, _TrayStuff)
		Return
	EndIf
EndFunc
#EndRegion
