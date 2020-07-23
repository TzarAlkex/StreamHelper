#cs
[FakeIniSectionName]
#ce
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Svartnos.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=StreamHelper
#AutoIt3Wrapper_Res_Fileversion=1.5.2.0
#AutoIt3Wrapper_Res_ProductVersion=1.5.2.0
#AutoIt3Wrapper_Res_LegalCopyright=©2015-2020 Alexander Samuelsson
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_Au3Stripper_OnError=ForceUse
#Au3Stripper_Parameters=/so /mi=100
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2 (Stable)
 Author:         Alexander Samuelsson AKA AdmiralAlkex

 Script Function:
	Stuff



Todo:
*Add back the quality stuff in the array now that Twitch changed how they allocate transcoding to non-partners?
*Always save quality stuff to array for partners?
*Beep confirmed as annoying.

*BroccoliCat on twitch doesn't load properly on source quality in livestreamer.
Increase the timer wait thing in the config file?
I have increased multiple seconds, difference is questionable?
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
NO IT CAN NOT!!

*Remake icon?
*Or redo in better quality (Square310x310Logo.scale-400.png is just a resized Square310x310Logo.scale-200.png)

*I'm pretty sure it just notified me of an ignored streamer changing game, verify and fix?

*Switch URL encoding UDF?
"Secondly, the best version I've seen has be ProgAndy's which features in the WinHTTP UDF."
https://www.autoitscript.com/forum/topic/95850-url-encoding/?do=findComment&comment=1019203

*Look at possibility to get streams from friends.

#cs
/// <summary>
/// Redirect user to Windows Store and open the review window for current App
/// </summary>
/// <returns>Task</returns>
public static async Task OpenStoreReviewAsync()
{
	var pfn = Package.Current.Id.FamilyName;
	await Launcher.LaunchUriAsync(new Uri("ms-windows-store://review/?PFN=" + pfn));
}
#ce

#cs
wintoast.exe --appname "Git for Windows" \
				--appid GitForWindows.Updater \
				--image /mingw$bit/share/git/git-for-windows.ico \
				--text "Download and install $name$warn?" \
				--action Yes --action No --expirems 15000
#ce

*https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/adaptive-interactive-toasts

*https://blogs.msdn.microsoft.com/lucian/2015/10/23/how-to-call-uwp-apis-from-a-desktop-vbc-app/

*https://docs.microsoft.com/en-us/uwp/api/windows.applicationmodel.startuptaskstate

*use mailgun for gathering feedback and logs?
https://www.mailgun.com/
https://documentation.mailgun.com/en/latest/index.html

*move Reset-button to the right of the username editbox?
*Change button to say "Forget ID & Username"?

*Make myself a install button to put on websites like http://vidcoder.net/ have
ms-windows-store://pdp/?productid=*12LETTERSANDNUMBERS*

*Detect if Tc is installed and enable a "Open chat in Tc" button on the "Play from clipboard"-window.
.\Tc.exe --channel="swebliss"
So stupid, --channel only works if Tc is not already running. And there isn't even a very nice way to close it to make a hack around it.

*remove $eTime, use $eCreated and generate time live on tooltip show instead

*add >:( to random places

*Use for refresh button? https://stackoverflow.com/a/54006960

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
#include "APIStuff.au3"
#include "CentennialHelper.au3"
#include <GuiListBox.au3>
#include <TrayConstants.au3>
#include <IE.au3>
#include "IE_EmbeddedVersioning.au3"
#include <Math.au3>
#include <StaticConstants.au3>

$iWM = _WinAPI_RegisterWindowMessage("AutoIt window with hopefully a unique title|Singleton")
_WinAPI_PostMessage($HWND_BROADCAST, $iWM, 0x1234, 0xABCD)

GUICreate("AutoIt window with hopefully a unique title|Senap the third")
GUIRegisterMsg($WM_POWERBROADCAST, "_PowerEvents")
GUIRegisterMsg($WM_ENDSESSION, "_EndSessionEvents")
GUIRegisterMsg($iWM, "_RemoteEvents")

TraySetToolTip("StreamHelper")
If (Not @Compiled) Then
	TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
EndIf

$iClosePreviousBeforePlaying = True

Global Enum $eAppX, $eClassic
Global $asInstallType[2]
$asInstallType[$eAppX] = "AppX"
$asInstallType[$eClassic] = "Classic"

Global $sLog = RegRead("HKCU\SOFTWARE\StreamHelper\", "Log")
_CW("Install type: " & _InstallType())

Global $iStreamlinkInstalled = StringInStr(EnvGet("path"), "Streamlink") > 0
_CW("Streamlink found: " & $iStreamlinkInstalled)

Global $sUpdateCheck
If _InstallType() = $asInstallType[$eAppX] Then
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
$sIgnoreMinutes = 0

Global $sNewUI = RegRead("HKCU\SOFTWARE\StreamHelper\", "NewUI")
Global $sNewUIMultipleThumbnails = _MultipleThumbnails()

$sStreamlinkEnabled = RegRead("HKCU\SOFTWARE\StreamHelper\", "StreamlinkEnabled")
If @error Then $sStreamlinkEnabled = String(Number($iStreamlinkInstalled))
_CW("Streamlink enabled: " & $sStreamlinkEnabled)
$sStreamlinkPath = RegRead("HKCU\SOFTWARE\StreamHelper\", "StreamlinkPath")
$sStreamlinkQuality = RegRead("HKCU\SOFTWARE\StreamHelper\", "StreamlinkQuality")
If @error Then $sStreamlinkQuality = "best"
$sStreamlinkCommandLine = RegRead("HKCU\SOFTWARE\StreamHelper\", "StreamlinkCommandLine")

Global $iSmashcastEnable = False, $iYoutubeEnable = False

$sTwitchId = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchId")
$sTwitchName = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchName")
$sTwitchToken = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchToken")
$sTwitchGamesMax = RegRead("HKCU\SOFTWARE\StreamHelper\", "TwitchGamesMax")
If @error Then $sTwitchGamesMax = 20
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

Global $sInternalVersion
If @Compiled Then
	$sInternalVersion = FileGetVersion(@AutoItExe)
Else
	$sInternalVersion = IniRead(@ScriptFullPath, "FakeIniSectionName", "#AutoIt3Wrapper_Res_Fileversion", "0.0.0.0")
EndIf

_Upgrade()
Global $asFavorites = _EnumValues("Favorite")
Global $asTwitchGames = _EnumValues("TwitchGames")

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)
Opt("GUIOnEventMode", 1)

TrayCreateItem("")
TrayCreateItem("Refresh")
TrayItemSetOnEvent(-1, _MAIN)

TrayCreateItem("Play from clipboard")
TrayItemSetOnEvent(-1, _GuiShow)

TrayCreateItem("")
TrayCreateItem("Settings")
TrayItemSetOnEvent(-1, _SettingsShow)

TrayCreateItem("Send feedback")
TrayItemSetOnEvent(-1, _FeedbackShow)

TrayCreateItem("About")
TrayItemSetOnEvent(-1, _About)

TrayCreateItem("Exit")
TrayItemSetOnEvent(-1, _Exit)

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime, $eOnline, $eService, $eQualities, $eFlags, $eUserID, $eGameID, $eChannelID, $eTimer, $eStreamID, $eOldStreamID, $eViewers, $eName, $eMax
Global Enum $eTwitch, $eSmashcast, $eMixer, $eYoutube
Global Enum Step *2 $eIsLink, $eIsText, $eIsStream

Global $sNew
Global $aStreams[0][$eMax]

Global $bBlobFirstRun = True

Global $sChanged

Global Const $AUT_WM_NOTIFYICON = $WM_USER + 1 ; Application.h
Global Const $AUT_NOTIFY_ICON_ID = 1 ; Application.h
Global Const $PBT_APMRESUMEAUTOMATIC =  0x12

AutoItWinSetTitle("AutoIt window with hopefully a unique title|Ketchup the second")
Global $TRAY_ICON_GUI = WinGetHandle(AutoItWinGetTitle()) ; Internal AutoIt GUI
Global $avDownloads[1][2]

Global $hGuiClipboard, $hGuiFeedback, $hGuiIEUI
Global $idLabel, $idQuality, $idUrl
_GuiCreate()
_FeedbackCreate()

Global $hGuiSettings
Global $idRefreshMinutes, $idIgnoreMinutes, $idUpdates, $idStartup, $idStartupTooltip, $idStartupLegacy, $idLog, $idLogDelete, $idTwitchId, $idTwitchName, $idTwitchGamesName, $idTwitchGamesID, $idTwitchGamesAdd, $idTwitchGamesList, $idTwitchGamesMax, $idMixerInput, $idMixerId, $idMixerName, $idSmashcastInput, $idSmashcastId, $idSmashcastName, $idYoutubeInput, $idYoutubeId, $idYoutubeName, $idNewUI, $idNewUIMultipleThumbnails, $idStreamlinkEnabled, $idStreamlinkPath, $idStreamlinkPathCheck, $idStreamlinkQuality, $idStreamlinkCommandLine

_SettingsCreate()

_GDIPlus_Startup()

Global $hBitmap, $hImage, $hGraphic
$hBitmap = _WinAPI_CreateSolidBitmap(0, 0xFFFFFF, 16, 16)
$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
$hGraphic = _GDIPlus_ImageGetGraphicsContext($hImage)

; https://www.autoitscript.com/forum/topic/199786-making-your-compiled-application-dpi-aware/
Global Const $DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED = -5
If @OSVersion = 'WIN_10' Then DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext" , "HWND", $DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED)

If @Compiled = 1 Then
	_WinAPI_RegisterApplicationRestart($RESTART_NO_REBOOT)
EndIf

Global $aoEvents[0]
If $sNewUI = 1 Then
	TraySetClick($TRAY_CLICK_SECONDARYDOWN)
	TraySetOnEvent($TRAY_EVENT_PRIMARYUP, _IEUI)
EndIf
If FileExists(@LocalAppDataDir & "\StreamHelper\arraydebug") Then
	HotKeySet("{PAUSE}", _ArrayDebug)
EndIf

_MAIN()

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

		$sNow = _NowCalc()

		For $iX = 0 To UBound($aData2) -1
			$sStreamID = Json_ObjGet($aData2[$iX], "id")
			$sUserID = "T" & Json_ObjGet($aData2[$iX], "user_id")
			$sGameID = Json_ObjGet($aData2[$iX], "game_id")

			$sTime = Json_ObjGet($aData2[$iX], "started_at")
			$sTitle = Json_ObjGet($aData2[$iX], "title")
			$sThumbnail = Json_ObjGet($aData2[$iX], "thumbnail_url")
			$sViewerCount = Json_ObjGet($aData2[$iX], "viewer_count")

			Local $aDate, $aTime
			_DateTimeSplit($sTime, $aDate, $aTime)
			Local $tSystem = _Date_Time_EncodeSystemTime($aDate[2], $aDate[3], $aDate[1], $aTime[1], $aTime[2], $aTime[3])
			$tLocal = _Date_Time_SystemTimeToTzSpecificLocalTime($tSystem)
			$sTimeConverted = _Date_Time_SystemTimeToDateTimeStr($tLocal, 1)

			$sTimeDiffHour = _DateDiff("h", $sTimeConverted, $sNow)
			$sTimeAdded = _DateAdd("h", $sTimeDiffHour, $sTimeConverted)
			$sTimeDiffMin = _DateDiff("n", $sTimeAdded, $sNow)
			$sTime2 = StringFormat("%02s:%02s", $sTimeDiffHour, $sTimeDiffMin)

			_StreamSet("", "", $sThumbnail, "", "", $sTime2, $sTitle, $eTwitch, $sUserID, $sStreamID, Default, $sGameID, $sViewerCount)
		Next
		If UBound($aData) <> 100 Then Return "Potato on a Stick"
	WEnd

	Return "Potato on a Stick"
EndFunc

Func _TwitchGetGames()
	If $asTwitchGames = "" Then Return

	$asGameIDs = StringSplit(StringStripWS($asTwitchGames, $STR_STRIPTRAILING), @LF)

	Local $sGames = ""
	For $iX = 1 To $asGameIDs[0]
		$sGames &= "&game_id=" & $asGameIDs[$iX]
	Next
	$sGames = StringTrimLeft($sGames, 1)

	$sUrl = "streams?" & $sGames & "&first=" & $sTwitchGamesMax
	$oJSON = _TwitchFetch($sUrl)
	If IsObj($oJSON) = False Then Return

	$aData = Json_ObjGet($oJSON, "data")
	If UBound($aData) = 0 Then Return

	$sNow = _NowCalc()

	For $iX = 0 To UBound($aData) -1
		$sGameID = Json_ObjGet($aData[$iX], "game_id")
		$sStreamID = Json_ObjGet($aData[$iX], "id")
		$sTime = Json_ObjGet($aData[$iX], "started_at")
		$sTitle = Json_ObjGet($aData[$iX], "title")
		$sUserID = "T" & Json_ObjGet($aData[$iX], "user_id")
		$sThumbnail = Json_ObjGet($aData[$iX], "thumbnail_url")
		$sViewerCount = Json_ObjGet($aData[$iX], "viewer_count")

		Local $aDate, $aTime
		_DateTimeSplit($sTime, $aDate, $aTime)
		Local $tSystem = _Date_Time_EncodeSystemTime($aDate[2], $aDate[3], $aDate[1], $aTime[1], $aTime[2], $aTime[3])
		$tLocal = _Date_Time_SystemTimeToTzSpecificLocalTime($tSystem)
		$sTimeConverted = _Date_Time_SystemTimeToDateTimeStr($tLocal, 1)

		$sTimeDiffHour = _DateDiff("h", $sTimeConverted, $sNow)
		$sTimeAdded = _DateAdd("h", $sTimeDiffHour, $sTimeConverted)
		$sTimeDiffMin = _DateDiff("n", $sTimeAdded, $sNow)
		$sTime2 = StringFormat("%02s:%02s", $sTimeDiffHour, $sTimeDiffMin)

		_StreamSet("", "", $sThumbnail, "", "", $sTime2, $sTitle, $eTwitch, $sUserID, $sStreamID, Default, $sGameID, $sViewerCount)
	Next
EndFunc

Func _TwitchProcessUserID()
	Local $sUsers = "", $iCount = 0
	For $iX = 0 To UBound($aStreams) -1
		If $aStreams[$iX][$eService] <> $eTwitch Then ContinueLoop
		If $aStreams[$iX][$eDisplayName] <> "" And $aStreams[$iX][$eUrl] <> "" Then ContinueLoop
		If $aStreams[$iX][$eOnline] <> True Then ContinueLoop

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
		Local $sName = ""

		$sDisplayName = Json_ObjGet($aData[$iX], "display_name")
		$sLogin = Json_ObjGet($aData[$iX], "login")
		$sID = Json_ObjGet($aData[$iX], "id")
		If StringIsASCII($sDisplayName) = 0 Then
			$sName = $sDisplayName
			$sDisplayName = $sLogin
		EndIf
		$sUrl = "https://www.twitch.tv/" & $sLogin

		For $iIndex = 0 To UBound($aStreams) -1
			If $aStreams[$iIndex][$eUserID] = "T" & $sID Then
				$aStreams[$iIndex][$eDisplayName] = $sDisplayName
				$aStreams[$iIndex][$eUrl] = $sUrl

				If $sName <> "" Then
					$aStreams[$iIndex][$eName] = $sName
				EndIf

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
		If $aStreams[$iX][$eOnline] <> True Then ContinueLoop

		If $aStreams[$iX][$eGameID] == "0" Or $aStreams[$iX][$eGameID] == "" Then
			$oJSON = _WinHttpFetch("api.twitch.tv", "kraken/channels/" & StringTrimLeft($aStreams[$iX][$eUserID], 1), "Accept: application/vnd.twitchtv.v5+json" & @CRLF & "Client-ID: " & $sTwitchClientID & @CRLF & "Authorization: OAuth " & $sTwitchToken)
			If IsObj($oJSON) = False Then Return

			$sGame = Json_ObjGet($oJSON, "game")
			$aStreams[$iX][$eGame] = $sGame
			ContinueLoop
		EndIf

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

;~ add &api_version=5 ??
Func _TwitchFetch($sUrl)
	Return _WinHttpFetch("api.twitch.tv", "helix/" & $sUrl, "Client-ID: " & $sTwitchClientID & @CRLF & "Authorization: Bearer " & $sTwitchToken)
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

	_MixerProcessStreams()

	$iTrayRefresh = True
EndFunc

Func _MixerGet()
	$iOffset = 0

	While 1
		Local $sUrl = "users/" & $sMixerId & "/follows?page=" & $iOffset & "&limit=100&where=online:eq:1&fields=id,token,name,viewersCurrent,type,user&noCount=1"
		$oFollows = _MixerFetch($sUrl)
		If UBound($oFollows) = 0 Then Return

		For $iX = 0 To UBound($oFollows) -1
			$sChannelID = Json_ObjGet($oFollows[$iX], "id")

			$sUrl = "https://mixer.com/" & Json_ObjGet($oFollows[$iX], "token")
			$sTitle = Json_ObjGet($oFollows[$iX], "name")
			$sViewerCount = Json_ObjGet($oFollows[$iX], "viewersCurrent")

			$oType = Json_ObjGet($oFollows[$iX], "type")
			If IsObj($oType) Then
				$sGame = Json_ObjGet($oType, "name")
			Else
				$sGame = "No game selected"
			EndIf

			$oUser = Json_ObjGet($oFollows[$iX], "user")
			$sDisplayName = Json_ObjGet($oUser, "username")
			$sUserID = "M" & Json_ObjGet($oUser, "id")

			$sThumbnail = "https://thumbs.mixer.com/channel/" & $sChannelID & ".small.jpg"

			_StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, "", "", $sTitle, $eMixer, $sUserID, Default, Default, Default, $sViewerCount, $sChannelID)
		Next
		If UBound($oFollows) <> 100 Then Return "Potato on a Stick"
		$iOffset += 1
	WEnd

	Return "Potato on a Stick"
EndFunc

Func _MixerProcessStreams()
	Local $sNow = _NowCalc()

	For $iX = 0 To UBound($aStreams) -1
		If $aStreams[$iX][$eService] <> $eMixer Then ContinueLoop
		If $aStreams[$iX][$eTime] <> "" Then ContinueLoop
		If $aStreams[$iX][$eOnline] <> True Then ContinueLoop

		$oBroadcast = _MixerFetch("channels/" & $aStreams[$iX][$eChannelID] & "/broadcast")   ; ?fields=id,startedAt doesn't work here
		$sTime = Json_ObjGet($oBroadcast, "startedAt")

		$sTime = StringRegExpReplace($sTime, "\.\d*", "", 1)   ; remove decimals
		$sTimeIso = _IsoDateTimeToZulu($sTime)

		Local $aDate, $aTime
		_DateTimeSplit($sTimeIso, $aDate, $aTime)
		Local $tSystem = _Date_Time_EncodeSystemTime($aDate[2], $aDate[3], $aDate[1], $aTime[1], $aTime[2], $aTime[3])
		$tLocal = _Date_Time_SystemTimeToTzSpecificLocalTime($tSystem)
		$sTimeConverted = _Date_Time_SystemTimeToDateTimeStr($tLocal, 1)

		$sTimeDiffHour = _DateDiff("h", $sTimeConverted, $sNow)
		$sTimeAdded = _DateAdd("h", $sTimeDiffHour, $sTimeConverted)
		$sTimeDiffMin = _DateDiff("n", $sTimeAdded, $sNow)
		$sTime2 = StringFormat("%02s:%02s", $sTimeDiffHour, $sTimeDiffMin)

		$aStreams[$iX][$eTime] = $sTime2
	Next
EndFunc

;Based on https://www.autoitscript.com/forum/topic/195291-datetime-conversion-issue/?do=findComment&comment=1400353
Func _IsoDateTimeToZulu($s)
    Local $sDT = StringLeft($s, 19)
    $sDT = StringRegExpReplace($sDT, '(\d{4}).(\d\d).(\d\d).(.{8})', '$1/$2/$3 $4')
    Local $iH = -Int(StringMid($s, 20, 3))
    Local $iM = Int(($iH < 0 ? '-' : '') & StringMid($s, 24, 2))
    Return StringRegExpReplace(_DateAdd('h', $iH, _DateAdd('n', $iM, $sDT)), '(\d{4})(/\d\d/)(\d\d)(.{9})', '$1$2$3$4')
EndFunc

Func _MixerFetch($sUrl)
	Return _WinHttpFetch("mixer.com", "api/v1/" & $sUrl, "Client-ID: " & $sMixerClientID)
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
	_CW("_WinHttpFetch: " & $sDomain & "/" & $sUrl & " \ " & StringReplace($sHeader, @CRLF, " \ "))

	Local $iTries = 0, $asResponse
	Do
		Sleep($iTries * 6000)

		Local $hOpen = _WinHttpOpen()
		Local $hConnect = _WinHttpConnect($hOpen, $sDomain)

		$asResponse = _WinHttpSimpleSSLRequest($hConnect, Default, $sUrl, Default, Default, $sHeader, True)

		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)

		$iTries += 1
	Until (IsArray($asResponse) And (StringSplit($asResponse[0], " ")[2] = 200 Or StringSplit($asResponse[0], " ")[2] = 404)) Or $iTries = 6

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
	Static Local $iRandomStreams = FileExists(@LocalAppDataDir & "\StreamHelper\randomstreams")

	_ArraySort($aStreams, 1)

	For $iX = 0 To UBound($aStreams) -1
		If $iRandomStreams Then
			If Random(0, 1, 1) Then
				$aStreams[$iX][$eOnline] = False
			EndIf
		EndIf
		If $aStreams[$iX][$eOnline] = True Then
			Local $sDisplayName = $aStreams[$iX][$eDisplayName]

			If BitAND($aStreams[$iX][$eFlags], $eIsStream) Then
				If StringInStr($asFavorites, $aStreams[$iX][$eUserID] & @LF, $STR_CASESENSE) Then $sDisplayName = $sDisplayName & " | F"
			EndIf

			Local $sTrayText = $sDisplayName
			If $aStreams[$iX][$eGame] <> "" Then $sTrayText &= " | " & $aStreams[$iX][$eGame]

			$sTrayText = StringReplace($sTrayText, "&", "&&")

			$aStreams[$iX][$eOnline] = False

			If $aStreams[$iX][$eTrayId] = 0 Then
				$aStreams[$iX][$eTrayId] = TrayCreateItem($sTrayText, -1, 0)
				If $aStreams[$iX][$eFlags] = $eIsStream Then
					Local $NewText = $aStreams[$iX][$eDisplayName]
					If $bBlobFirstRun <> True Then $NewText &= " - " & $aStreams[$iX][$eGame] & "@CRLF" & $aStreams[$iX][$eStatus]

					If $aStreams[$iX][$eStreamID] = 404 Or $aStreams[$iX][$eStreamID] <> $aStreams[$iX][$eOldStreamID] Then
						$aStreams[$iX][$eOldStreamID] = $aStreams[$iX][$eStreamID]

						If StringInStr($sDisplayName, " | F", $STR_CASESENSE) And ($sIgnoreMinutes = 0 Or TimerDiff($aStreams[$iX][$eTimer]) * 1000 * 60 > $sIgnoreMinutes) Then
							$aStreams[$iX][$eTimer] = TimerInit()

							$sNew &= $NewText & @CRLF
						EndIf
					EndIf
				EndIf
				TrayItemSetOnEvent( -1, _TrayStuff)
			Else
				If $sTrayText = TrayItemGetText($aStreams[$iX][$eTrayId]) Then ContinueLoop

				TrayItemSetText($aStreams[$iX][$eTrayId], $sTrayText)

				If StringInStr($sDisplayName, " | F", $STR_CASESENSE) Then
					Local $NewText = $aStreams[$iX][$eDisplayName] & " - " & $aStreams[$iX][$eGame] & " - " & $aStreams[$iX][$eTime] & "@CRLF" & $aStreams[$iX][$eStatus]

					$sChanged &= $NewText & @CRLF
				EndIf
			EndIf
		Else
			If $aStreams[$iX][$eTrayId] <> 0 And BitAND($aStreams[$iX][$eFlags], $eIsStream) = $eIsStream Then
				TrayItemDelete($aStreams[$iX][$eTrayId])
				$aStreams[$iX][$eTrayId] = 0
				$aStreams[$iX][$eTime] = ""
			EndIf
		EndIf
	Next
EndFunc

Func _TrayStuff()
	For $iX = 0 To UBound($aStreams) -1
		If $aStreams[$iX][$eTrayId] = @TRAY_ID Then
			ExitLoop
		EndIf
	Next

	If BitAND($aStreams[$iX][$eFlags], $eIsLink) = $eIsLink Then
		ShellExecute($aStreams[$iX][$eUrl])
	ElseIf BitAND($aStreams[$iX][$eFlags], $eIsText) = $eIsText Then
		Return
	ElseIf BitAND($aStreams[$iX][$eFlags], $eIsStream) = $eIsStream Then
		If _IsPressed("10") Then
			Local $asStream[] = [$aStreams[$iX][$eUrl], $aStreams[$iX][$eDisplayName]]
			_ClipboardGo($asStream)
		ElseIf _IsPressed("11") Then
			$sUserID = $aStreams[$iX][$eUserID]

			If StringInStr($asFavorites, $sUserID, $STR_CASESENSE) Then   ; if fav then remove it from fav
				$asFavorites = StringReplace($asFavorites, $sUserID & @LF, "")
				RegDelete("HKCU\SOFTWARE\StreamHelper\Favorite\", $sUserID)
			Else   ; if nothing then fav
				$asFavorites &= $sUserID & @LF
				RegWrite("HKCU\SOFTWARE\StreamHelper\Favorite\", $sUserID, "REG_SZ", "")
			EndIf

			Local $sDisplayName = $aStreams[$iX][$eDisplayName]
			If StringInStr($asFavorites, $aStreams[$iX][$eUserID] & @LF, $STR_CASESENSE) Then $sDisplayName = $sDisplayName & " | F"

			;Shouldn't this also have an if not game then skip game display?
			;Future me: Yes. Yes it should.
			Local $NewText = $sDisplayName
			If $aStreams[$iX][$eGame] <> "" Then $NewText &= " | " & $aStreams[$iX][$eGame]
			TrayItemSetText($aStreams[$iX][$eTrayId], $NewText)
		ElseIf $sStreamlinkEnabled = "1" Then
			_StreamlinkPlay($aStreams[$iX][$eUrl])
		Else
			ShellExecute($aStreams[$iX][$eUrl])
		EndIf
	EndIf
EndFunc

Func _StreamlinkPlay($sUrl, $sQuality = "")
	Static Local $iPID = 0

	;_GuiPlay can send empty $sQuality so conversion has to be done
	If $sQuality = "" Then $sQuality = $sStreamlinkQuality

	If $iClosePreviousBeforePlaying Then
		If _WinAPI_GetProcessName($iPID) = "streamlink.exe" Then
			RunWait("taskkill.exe /PID " & $iPID & " /T", "", @SW_HIDE)
			ProcessWaitClose($iPID, 1000)
		EndIf
	EndIf

	Local $sProgram = "streamlink.exe"
	If $sStreamlinkPath Then
		$sProgram = '"' & $sStreamlinkPath & '"'
	EndIf
	$sProgram &= " " & $sStreamlinkCommandLine
	$sProgram &= " --twitch-disable-hosting"
	$sProgram &= " " & $sUrl
	$sProgram &= " " & $sQuality

	$iPID = Run($sProgram, "", @SW_HIDE)
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
	_IEUIRefresh()

	;https://www.autoitscript.com/forum/topic/146955-solved-remove-crlf-at-the-end-of-text-file/?do=findComment&comment=1041088
	If StringRight($sNew, 2) = @CRLF Then $sNew = StringTrimRight($sNew, 2)
	If StringRight($sChanged, 2) = @CRLF Then $sChanged = StringTrimRight($sChanged, 2)
	If (Not @Compiled) Then
		TraySetIcon(@ScriptDir & "\Svartnos.ico", -1)
	Else
		TraySetIcon()
	EndIf

	_CW("New streamer: " & StringReplace(StringReplace($sNew, "@CRLF", " - "), @CRLF, ", "))
	_CW("Streamer changed game: " & StringReplace(StringReplace($sChanged, "@CRLF", " - "), @CRLF, ", "))

	If $sChanged <> "" Then
		If @OSBuild >= 10240 Then
			_TrayTipThis8($sChanged, "Changed game")
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
			TrayTip("Currently streaming", $sReplaced, 10)
		ElseIf @OSBuild >= 10240 Then
			_TrayTipThis8($sNew, "Now streaming")
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

Func _TrayTipThis6($sText, $sTitle)
	$asSplit = StringSplit($sText, @CRLF, $STR_ENTIRESPLIT)

	For $iX = $asSplit[0] To 1 Step -1
		Local $sName = StringReplace($asSplit[$iX], "@CRLF", @CRLF)
		If $iX = 1 Then
			TrayTip($sTitle, $sName, 10)
		Else
			TrayTip($sTitle & " (" & $iX -1 & " more)", $sName, 10)
		EndIf
	Next
EndFunc

Func _TrayTipThis7($sText, $sTitle)
	$asSplit = StringSplit($sText, @CRLF, $STR_ENTIRESPLIT)

	For $iX = $asSplit[0] To 1 Step -1
		Local $sName = StringReplace($asSplit[$iX], "@CRLF", @CRLF)
		Run(@ScriptDir & '\WinToast.exe --appname "StreamHelper" --appid 11146AlexanderSamuelsson.StreamHelper_b4j1319m6fkgc --text "' & $sName & '" --attribute ""', @ScriptDir)   ; Doesn't work
	Next
EndFunc

Func _TrayTipThis8($sText, $sTitle)
	$asSplit = StringSplit($sText, @CRLF, $STR_ENTIRESPLIT)

	For $iX = $asSplit[0] To 1 Step -1
		Local $sName = StringSplit($asSplit[$iX], "@CRLF", $STR_ENTIRESPLIT)
		If $sName[0] = 2 Then
			TrayTip($sName[1], $sName[2], 10)
		EndIf
	Next
EndFunc

Func _GuiCreate()
	Local $iGuiWidth = 510, $iGuiHeight = 70

	$hGuiClipboard = GUICreate("Copy Streamlink compatible link to clipboard", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	If @Compiled = False Then GUISetIcon(@ScriptDir & "\Svartnos.ico")

	$idLabel = GUICtrlCreateLabel("I am word", 70, 10, 350, 20)
	$idQuality = GUICtrlCreateCombo("", 70, 40, 160, 20)
	$idPlay = GUICtrlCreateButton("Play", 240, 40, 60, 20)
	GUICtrlSetOnEvent(-1, _GuiPlay)
	$idDownload = GUICtrlCreateButton("Download", 310, 40, 80, 20)
	GUICtrlSetOnEvent(-1, _GuiDownload)
	$idBrowser = GUICtrlCreateButton("Open in browser", 400, 40, 100, 20)
	GUICtrlSetOnEvent(-1, _GuiBrowser)
	$idUrl = GUICtrlCreateDummy()

	GUISetOnEvent($GUI_EVENT_CLOSE, _GuiHide)
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
	If $sQuality = "" Then $sQuality = $sStreamlinkQuality

	Local $sUrl = GUICtrlRead($idUrl)

	Local $sProgram = "streamlink.exe"
	If $sStreamlinkPath Then
		$sProgram = '"' & $sStreamlinkPath & '"'
	EndIf
	$sProgram &= " " & $sStreamlinkCommandLine
	$sProgram &= " --twitch-disable-hosting"
	$sProgram &= ' --output "' & $sPathToFile & '"'
	$sProgram &= " " & $sUrl
	$sProgram &= " " & $sQuality

	$iPid = Run($sProgram, "", @SW_HIDE, BitOR($STDOUT_CHILD, $STDERR_CHILD))
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

Func _GuiShow()
	Local $sClipboard = ClipGet()
	Local $asStream[] = [$sClipboard]
	_ClipboardGo($asStream)
EndFunc

Func _ClipboardGo($asStream)
	Local $sTitle
	Local $sUrl = $asStream[0]

	If $sStreamlinkEnabled = "0" Then
		If MsgBox($MB_YESNO, @ScriptName, "Streamlink not found or disabled, open url in browser instead?") = $IDYES Then
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

	If _IsPressed("10") Then
		WinSetTitle($hGuiClipboard, "", StringTrimRight(@ScriptName, 4) & " - To infinity... and beyond!")
	Else
		WinSetTitle($hGuiClipboard, "", StringTrimRight(@ScriptName, 4) & " - Copy Streamlink compatible link to clipboard")
	EndIf

	$asQualities = _GetQualities($sUrl)
	$sQualities = _ArrayToString($asQualities)

	Local $sQuality = "no default"
	If StringInStr($sQualities, "Error") Then
		$sQuality = "Error"
	ElseIf StringInStr($sQualities, $sStreamlinkQuality) Then
		$sQuality = $sStreamlinkQuality
	ElseIf $sQuality = "no default" Then
		$sQuality = $asQualities[UBound($asQualities) -1]
	EndIf

	GUICtrlSetData($idQuality, $sQualities, $sQuality)

	GUICtrlSetState($idQuality, $GUI_SHOW)
EndFunc

Func _GuiHide()
	GUISetState(@SW_HIDE, $hGuiClipboard)
EndFunc

Func _About()
	If _IsPressed("10") Then
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
	Else
		MsgBox(0, StringTrimRight(@ScriptName, 4), "Created by Alexander Samuelsson")
	EndIf
EndFunc

Func _Exit()
	Exit
EndFunc
#EndRegion GUI

#Region FEEDBACK-GUI
Func _FeedbackCreate()
	$hGuiFeedback = GUICreate(StringTrimRight(@ScriptName, 4) & " - Feedback", 320, 50, -1, -1, -1)
	If @Compiled = False Then GUISetIcon(@ScriptDir & "\Svartnos.ico")

	GUICtrlCreateButton("Open Feedback Hub", 10, 10, 145, 30)
	GUICtrlSetOnEvent(-1, _FeedbackFeedbackHub)
	GUICtrlCreateButton("Open GitHub in browser", 165, 10, 145, 30)
	GUICtrlSetOnEvent(-1, _FeedbackGithub)

	GUISetOnEvent($GUI_EVENT_CLOSE, _FeedbackHide)
EndFunc

Func _FeedbackFeedbackHub()
	ShellExecute("windows-feedback:///?appid=11146AlexanderSamuelsson.StreamHelper_b4j1319m6fkgc!StreamHelper")
EndFunc

Func _FeedbackGithub()
	ShellExecute("https://github.com/TzarAlkex/StreamHelper/issues")
EndFunc

Func _FeedbackShow()
	If Not GUISetState(@SW_SHOW, $hGuiFeedback) Then WinActivate($hGuiFeedback)
EndFunc

Func _FeedbackHide()
	GUISetState(@SW_HIDE, $hGuiFeedback)
EndFunc
#EndRegion FEEDBACK-GUI

#Region SETTINGS-GUI
Func _SettingsCreate()
	Local $iGuiWidth = 430, $iGuiHeight = 220
	$hGuiSettings = GUICreate(StringTrimRight(@ScriptName, 4) & " " & $sInternalVersion & " (" & _InstallType() & ")" & "", $iGuiWidth, $iGuiHeight, -1, -1, -1)
	If @Compiled = False Then GUISetIcon(@ScriptDir & "\Svartnos.ico")

	GUICtrlCreateTab(10, 10, $iGuiWidth - 20, $iGuiHeight - 20)


	GUICtrlCreateTabItem("Settings")

	GUICtrlCreateLabel("Minutes between refresh", 20, 40)
	$idRefreshMinutes = GUICtrlCreateInput($sRefreshMinutes, 20, 60, 80, 20, BitOR($GUI_SS_DEFAULT_INPUT, $ES_NUMBER))
	GUICtrlCreateUpdown(-1, $UDS_ARROWKEYS)
	GUICtrlSetLimit(-1, 120, 3)

	If False Then
		GUICtrlCreateLabel("Minutes to ignore repeat notifications", 155, 40)
		$idIgnoreMinutes = GUICtrlCreateInput($sIgnoreMinutes, 155, 60, 80, 20, BitOR($GUI_SS_DEFAULT_INPUT, $ES_NUMBER))
		GUICtrlCreateUpdown(-1, $UDS_ARROWKEYS)
		GUICtrlSetLimit(-1, 120, 3)
	EndIf

	If _InstallType() <> $asInstallType[$eAppX] Then
		GUICtrlCreateLabel("Check for updates", 20, 90)
		$idUpdates = GUICtrlCreateCombo("", 20, 110, 80)
		GUICtrlSetData(-1, "Never|Daily|Weekly|Monthly", $sUpdateCheck)
		GUICtrlCreateButton("Check now", 110, 110)
		GUICtrlSetOnEvent(-1, _CheckNow)
	EndIf

	If _InstallType() = $asInstallType[$eAppX] Then
		$avStatus = _StartupTaskStatusByID("MainStartupTask")
;~ 		$avStatus = _StartupTaskStatusByIndex(0)
		_CW("_StartupTaskStatus(): " & $avStatus[0])
		If $avStatus[0] <> $eStateError Then
			$idStartup = GUICtrlCreateCheckbox("Start automatically on user login", 20, 140)
			GUICtrlSetOnEvent(-1, _CentennialStartupSet)
			$aiPos = ControlGetPos($hGuiSettings, "", $idStartup)
			$idStartupTooltip = GUICtrlCreateLabel("", $aiPos[0], $aiPos[1], $aiPos[2], $aiPos[3])

			_CentennialStartupUI($avStatus[0])
		EndIf
	Else
		$idStartupLegacy = GUICtrlCreateCheckbox("Start automatically on user login", 20, 140)
		GUICtrlSetOnEvent(-1, _LegacyStartupSet)

		If FileExists(@StartupDir & "\StreamHelper.lnk") Then GUICtrlSetState(-1, $GUI_CHECKED)

		If @Compiled = 0 Then
			GUICtrlSetState(-1, $GUI_DISABLE)
			$aiPos = ControlGetPos($hGuiSettings, "", $idStartupLegacy)
			GUICtrlCreateLabel("", $aiPos[0], $aiPos[1], $aiPos[2], $aiPos[3])
			GUICtrlSetTip(-1, "Not available while running from source")
		EndIf
	EndIf

	$idLog = GUICtrlCreateCheckbox("Save log to file (don't enable unless asked)", 20, 170)
	If $sLog = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateButton("Open log folder", $iGuiWidth - 105, 135)
	GUICtrlSetOnEvent(-1, _LogFolderOpen)

	$idLogDelete = GUICtrlCreateButton("Delete logs (XXX MB)", $iGuiWidth - 135, 170)
	GUICtrlSetOnEvent(-1, _LogFolderDelete)


	GUICtrlCreateTabItem("Twitch - Followed")
	GUICtrlCreateLabel('1. Click "Log in (Opens in browser)"' & @CRLF & "2. After login, select all the text in the textbox and copy it" & @CRLF & '3. Click "Paste login info"', 20, 40)

	GUICtrlCreateButton("Log in (Opens in browser)", 20, 90, 190)
	GUICtrlSetOnEvent(-1, _TwitchLogIn)
	GUICtrlCreateButton("Paste login info", 220, 90, 140)
	GUICtrlSetOnEvent(-1, _TwitchGetInfo)

	GUICtrlCreateLabel("Saved ID", 20, 160)
	$idTwitchId = GUICtrlCreateInput($sTwitchId, 20, 180, 120, Default, $ES_READONLY)
	GUICtrlCreateLabel("Saved Username", 155, 160)
	$idTwitchName = GUICtrlCreateInput($sTwitchName, 155, 180, 120, Default, $ES_READONLY)
	GUICtrlCreateButton("Forget ID && Username", 290, 177)
	GUICtrlSetOnEvent(-1, _TwitchReset)


	GUICtrlCreateTabItem("Twitch - Games")

	GUICtrlCreateLabel("1. Input game name" & @CRLF & "exactly as it shows on Twitch ", 20, 40)
	GUICtrlCreateLabel(" ", 20, 40)
	$idTwitchGamesName = GUICtrlCreateInput("", 20, 75, 190)
	_GUICtrlEdit_SetCueBanner($idTwitchGamesName, "Game name")
	GUICtrlCreateButton("2. Get ID", 20, 100)
	GUICtrlSetOnEvent(-1, _TwitchGameID)
	GUICtrlCreateLabel(" ", 20, 40)
	$idTwitchGamesID = GUICtrlCreateInput("", 20, 130, 190)
	GUICtrlSetState(-1, $GUI_DISABLE)
	$idTwitchGamesAdd = GUICtrlCreateButton("3. Add", 20, 155)
	GUICtrlSetOnEvent(-1, _TwitchGameAdd)
	GUICtrlSetState(-1, $GUI_DISABLE)

	$idTwitchGamesList = GUICtrlCreateList("", 260, 40, 150, 85)
	GUICtrlSetData(-1, StringReplace(StringStripWS($asTwitchGames, $STR_STRIPTRAILING), @LF, "|"))

	GUICtrlCreateButton("Remove selected", 260, 125)
	GUICtrlSetOnEvent(-1, _TwitchGameRemove)

	GUICtrlCreateLabel("Max streams to get", 260, 160)
	$idTwitchGamesMax = GUICtrlCreateInput($sTwitchGamesMax, 260, 180, 60, 20, BitOR($GUI_SS_DEFAULT_INPUT, $ES_NUMBER))
	GUICtrlCreateUpdown(-1, $UDS_ARROWKEYS)
	GUICtrlSetLimit(-1, 100, 1)


	GUICtrlCreateTabItem("Mixer")
	GUICtrlCreateLabel("1. Input username" & @CRLF & "2. Click Get ID", 20, 40)

	GUICtrlCreateLabel(" ", 20, 70)
	$idMixerInput = GUICtrlCreateInput("", 20, 90, 190)
	_GUICtrlEdit_SetCueBanner($idMixerInput, "Username")
	GUICtrlCreateButton("Get ID", 220, 87)
	GUICtrlSetOnEvent(-1, _MixerGetId)

	GUICtrlCreateLabel("Saved ID", 20, 160)
	$idMixerId = GUICtrlCreateInput($sMixerId, 20, 180, 120, Default, $ES_READONLY)
	GUICtrlCreateLabel("Saved Username", 155, 160)
	$idMixerName = GUICtrlCreateInput($sMixerName, 155, 180, 120, Default, $ES_READONLY)
	GUICtrlCreateButton("Forget ID && Username", 290, 177)
	GUICtrlSetOnEvent(-1, _MixerReset)


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


	GUICtrlCreateTabItem("New UI (beta)")

	GUICtrlCreateLabel("Consider this beta." & @CRLF & "Features might be missing and there might be bugs!" & @CRLF & @CRLF & "After you enable:" & @CRLF & "Left-click tray icon to show the New UI, right-click to show the old one.", 20, 40)
	$idNewUI = GUICtrlCreateCheckbox("Activate New UI (beta)", 20, 155)
	If $sNewUI = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateLabel("Number of simultaneous thumbnail downloads:", 20, 180, 230, Default, $SS_CENTERIMAGE)
	GUICtrlSetTip(-1, "Needs a restart to apply")

	$idNewUIMultipleThumbnails = GUICtrlCreateCombo("", 250, 180, 80)
	Local $sMultipleThumbnails = "2|6"
	If StringInStr($sMultipleThumbnails, $sNewUIMultipleThumbnails) = 0 Then $sMultipleThumbnails &= "|" & $sNewUIMultipleThumbnails
	GUICtrlSetData(-1, $sMultipleThumbnails, $sNewUIMultipleThumbnails)
	GUICtrlSetTip(-1, "Needs a restart to apply")
	Local $tInfo
	_GUICtrlComboBox_GetComboBoxInfo($idNewUIMultipleThumbnails, $tInfo)
	$hEdit = DllStructGetData($tInfo, "hEdit") ; Handle to the Edit Box
	$iStyle   = _WinAPI_GetWindowLong($hEdit, $GWL_STYLE) ; Get current style
	_WinAPI_SetWindowLong($hEdit, $GWL_STYLE, BitOr($iStyle, $ES_NUMBER)) ; Add number only style


	GUICtrlCreateTabItem("Streamlink")

	If $iStreamlinkInstalled Then
		GUICtrlCreateLabel("Streamlink installation found in PATH", 20, 40)
	Else
		GUICtrlCreateLabel("Streamlink not found", 20, 40)
	EndIf

	$idStreamlinkEnabled = GUICtrlCreateCheckbox("Enabled", 20, 60)
	If $sStreamlinkEnabled = "1" Then GUICtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateLabel("Custom path to executable", 20, 105)
	$idStreamlinkPath = GUICtrlCreateInput($sStreamlinkPath, 20, 125, 160)
	_GUICtrlEdit_SetCueBanner(-1, "C:\example\streamlink.exe")
	GUICtrlSetTip(-1, "Not needed if in PATH")
	GUICtrlSetOnEvent(-1, _StreamlinkPathCheck)

	$idStreamlinkPathCheck = GUICtrlCreateLabel(" ", 190, 125)

	GUICtrlCreateLabel("Default quality", 250, 105)
	$idStreamlinkQuality = GUICtrlCreateCombo("", 250, 125, 160)
	Local $sQualities = "best|worst|audio_only"
	If StringInStr($sQualities, $sStreamlinkQuality) = 0 Then $sQualities &= "|" & $sStreamlinkQuality
	GUICtrlSetData(-1, $sQualities, $sStreamlinkQuality)

	GUICtrlCreateLabel("Extra command line parameters", 20, 155)
	$idStreamlinkCommandLine = GUICtrlCreateInput($sStreamlinkCommandLine, 20, 175, 390)


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

	Local $avStatus
	If $iChecked Then
		$avStatus = _StartupTaskEnableByID("MainStartupTask")
	Else
		$avStatus = _StartupTaskDisableByID("MainStartupTask")
	EndIf
	_CentennialStartupUI($avStatus[0])
EndFunc

Func _CentennialStartupUI($iStatus)
	If $iStatus = $eStateError Then
		GUICtrlSetState($idStartup, $GUI_INDETERMINATE)
		GUICtrlSetTip($idStartupTooltip, "Error?")
	ElseIf $iStatus = $eStateDisabled Then
		GUICtrlSetState($idStartup, $GUI_UNCHECKED)
		GUICtrlSetTip($idStartupTooltip, "")
	ElseIf $iStatus = $eStateDisabledByUser Then
		GUICtrlSetState($idStartup, $GUI_DISABLE)
		GUICtrlSetTip($idStartupTooltip, "Can't set autostart if disabled from Task Manager. Enable from there first.")
	ElseIf $iStatus = $eStateEnabled Then
		GUICtrlSetState($idStartup, $GUI_CHECKED)
		GUICtrlSetTip($idStartupTooltip, "")
	ElseIf $iStatus = $eStateDisabledByPolicy Then
		GUICtrlSetState($idStartup, $GUI_DISABLE)
		GUICtrlSetTip($idStartupTooltip, "The task is disabled by the administrator or group policy.")
	ElseIf $iStatus = $eStateEnabledByPolicy Then
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

Func _TwitchLogIn()
	ShellExecute("https://id.twitch.tv/oauth2/authorize?client_id=" & $sTwitchClientID & "&redirect_uri=" & $sTwitchRedirectURI & "&response_type=token")
EndFunc

Func _TwitchGetInfo()
	Local $sClipboard = ClipGet()
	Local $asLogin = StringSplit($sClipboard, ";")

	If UBound($asLogin) = 4 Then
		_TwitchSet($asLogin[1], $asLogin[2], $asLogin[3])
	Else
		MsgBox($MB_OK, @ScriptName, "Invalid data", Default, $hGuiSettings)
	EndIf
EndFunc

Func _TwitchReset()
	_TwitchSet("", "", "")
EndFunc

Func _TwitchSet($sId, $sName, $sToken)
	$sTwitchId = $sId
	$sTwitchName = $sName
	$sTwitchToken = $sToken
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchId", "REG_SZ", $sId)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchName", "REG_SZ", $sName)
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchToken", "REG_SZ", $sToken)
	GUICtrlSetData($idTwitchId, $sId)
	GUICtrlSetData($idTwitchName, $sName)
EndFunc

Func _TwitchGameID()
	If $sTwitchId = "" Then
		MsgBox($MB_ICONERROR, @ScriptName, 'Log in on the "Twitch - Followed" tab first', Default, $hGuiSettings)
		Return
	EndIf

	$sGameName = GUICtrlRead($idTwitchGamesName)
	If $sGameName = "" Then Return _TwitchGameRefresh()

	$oJSON = _TwitchFetch("games?name=" & $sGameName)
	If IsObj($oJSON) = False Then Return _TwitchGameRefresh()

	$aData = Json_ObjGet($oJSON, "data")
	If UBound($aData) = 0 Then Return _TwitchGameRefresh()
	$sGameID = Json_ObjGet($aData[0], "id")

	If $sGameID <> "" Then
		Return _TwitchGameRefresh($sGameID)
	Else
		Return _TwitchGameRefresh()
	EndIf
EndFunc

Func _TwitchGameRefresh($sGameID = "")
	GUICtrlSetData($idTwitchGamesID, $sGameID)

	If $sGameID Then
		GUICtrlSetState($idTwitchGamesAdd, $GUI_ENABLE)
	Else
		GUICtrlSetState($idTwitchGamesAdd, $GUI_DISABLE)
		Return MsgBox($MB_OK, @ScriptName, "Game not found, make sure you typed it correctly and are connected to the internet", Default, $hGuiSettings)
	EndIf
EndFunc

Func _TwitchGameAdd()
	$sID = GUICtrlRead($idTwitchGamesID)

	If StringInStr($asTwitchGames, $sID & @LF) <> 0 Then
		Return MsgBox($MB_OK, @ScriptName, "ID already in list", Default, $hGuiSettings)
	EndIf

	If _GUICtrlListBox_GetCount($asTwitchGames) > 10 Then
		Return MsgBox($MB_OK, @ScriptName, "10 games max currently", Default, $hGuiSettings)
	EndIf

	GUICtrlSetData($idTwitchGamesList, $sID & "|")
	$asTwitchGames &= $sID & @LF
	RegWrite("HKCU\SOFTWARE\StreamHelper\TwitchGames\", $sID, "REG_SZ", "")
EndFunc

Func _TwitchGameRemove()
	$iSelected = _GUICtrlListBox_GetCurSel($idTwitchGamesList)
	If $iSelected = -1 Then Return

	$sID = _GUICtrlListBox_GetText($idTwitchGamesList, $iSelected)

	_GUICtrlListBox_DeleteString($idTwitchGamesList, $iSelected)
	$asTwitchGames = StringReplace($asTwitchGames, $sID & @LF, "")
	RegDelete("HKCU\SOFTWARE\StreamHelper\TwitchGames\", $sID)
EndFunc

Func _TwitchGamesMax()
	Local $sNew = GUICtrlRead($idTwitchGamesMax)
	If $sNew = $sTwitchGamesMax Then Return
	$sTwitchGamesMax = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "TwitchGamesMax", "REG_SZ", $sTwitchGamesMax)
EndFunc

Func _MixerGetId()
	$sUsername = GUICtrlRead($idMixerInput)
	If $sUsername = "" Then Return _GetErrored()
	$sUsername = StringStripWS($sUsername, $STR_STRIPALL)
	$sQuotedUsername = URLEncode($sUsername)

	$oJSON = _MixerFetch("channels/" & $sQuotedUsername & "?fields=userId")
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

Func _NewUI()
	Local $sNew = BitAND(GUICtrlRead($idNewUI), $GUI_CHECKED)
	If $sNew = $sNewUI Then Return
	$sNewUI = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "NewUI", "REG_SZ", $sNewUI)

	If $sNewUI = 1 Then
		TraySetClick($TRAY_CLICK_SECONDARYDOWN)
		TraySetOnEvent($TRAY_EVENT_PRIMARYUP, _IEUI)
	Else
		TraySetClick($TRAY_CLICK_PRIMARYDOWN + $TRAY_CLICK_SECONDARYDOWN)
		If StringReplace(@AutoItVersion, ".", "") > 33150 Then
			TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "")
		Else
			TraySetOnEvent($TRAY_EVENT_PRIMARYUP, _TraySetOnEventHack)
		EndIf
	EndIf
EndFunc

Func _TraySetOnEventHack()
	Return
EndFunc

Func _GetExecutable()
	Local Static $sFileName = "", $sExtension = ""
	If $sFileName <> "" Then Return $sFileName & $sExtension

	Local $sDrive = "", $sDir = ""
	_PathSplit(@AutoItExe, $sDrive, $sDir, $sFileName, $sExtension)

	Return $sFileName & $sExtension
EndFunc

Func _MultipleThumbnails()
	Local $sExe = _GetExecutable()
	Local $HTTP1 = RegRead("HKCU\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER\", $sExe)
	Local $HTTP11 = RegRead("HKCU\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER\", $sExe)

	Return _Max(Number($HTTP1), Number($HTTP11))
EndFunc

Func _NewUIMultipleThumbnails()
	Local $sNew = GUICtrlRead($idNewUIMultipleThumbnails)
	If $sNew = $sNewUIMultipleThumbnails Then Return
	$sNewUIMultipleThumbnails = $sNew

	Local $sExe = _GetExecutable()
	RegWrite("HKCU\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER\", $sExe, "REG_DWORD", _Max(1, Number($sNewUIMultipleThumbnails)))
	RegWrite("HKCU\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER\", $sExe, "REG_DWORD", _Max(1, Number($sNewUIMultipleThumbnails)))
EndFunc

Func _StreamlinkEnabled()
	Local $sNew = GUICtrlRead($idStreamlinkEnabled)
	If $sNew = $sStreamlinkEnabled Then Return
	$sStreamlinkEnabled = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "StreamlinkEnabled", "REG_SZ", $sStreamlinkEnabled)
EndFunc

Func _StreamlinkPath()
	Local $sNew = GUICtrlRead($idStreamlinkPath)
	If $sNew = $sStreamlinkPath Then Return
	$sStreamlinkPath = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "StreamlinkPath", "REG_SZ", $sStreamlinkPath)
EndFunc

Func _StreamlinkQuality()
	Local $sNew = GUICtrlRead($idStreamlinkQuality)
	If $sNew = $sStreamlinkQuality Then Return
	$sStreamlinkQuality = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "StreamlinkQuality", "REG_SZ", $sStreamlinkQuality)
EndFunc

Func _StreamlinkCommandLine()
	Local $sNew = GUICtrlRead($idStreamlinkCommandLine)
	If $sNew = $sStreamlinkCommandLine Then Return
	$sStreamlinkCommandLine = $sNew
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "StreamlinkCommandLine", "REG_SZ", $sStreamlinkCommandLine)
EndFunc

Func _StreamlinkPathCheck()
	GUICtrlSetData($idStreamlinkPathCheck, "⏳")

	Local $sProgram = GUICtrlRead($idStreamlinkPath)
	If $sProgram = "" Then $sProgram = "streamlink.exe"
	$sProgram &= " --version"

	Local $iPID = Run($sProgram, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)

	_CW("PathCheck: " & $sOutput)

	If StringInStr($sOutput, "streamlink") Then
		GUICtrlSetData($idStreamlinkPathCheck, "✔")
	Else
		GUICtrlSetData($idStreamlinkPathCheck, "❌")
	EndIf
EndFunc

Func _GetErrored()
	MsgBox($MB_OK, @ScriptName, "ID not found, make sure you typed your username correctly and are connected to the internet", Default, $hGuiSettings)
EndFunc

Func _SettingsSaveAll()
	_SettingsRefresh()
	_SettingsIgnore()
	_SettingsUpdateCheck()
	_SettingsLog()
	_TwitchGamesMax()
	_NewUI()
	_NewUIMultipleThumbnails()
	_StreamlinkEnabled()
	_StreamlinkPath()
	_StreamlinkQuality()
	_StreamlinkCommandLine()
EndFunc

Func _SettingsShow()
	GUICtrlSetData($idLogDelete, "Delete logs (" & _LogSize() & " MB)")
	If Not GUISetState(@SW_SHOW, $hGuiSettings) Then WinActivate($hGuiSettings)
EndFunc

Func _SettingsHide()
	_SettingsSaveAll()
	GUISetState(@SW_HIDE, $hGuiSettings)
EndFunc
#EndRegion

#Region IE UI - INTERFACE2
Func _IEUI()
	Static Local $oIE
	Local $iMaximized = False

	_CW("VarGetType($oIE): " & VarGetType($oIE))
	_CW("IsObj($oIE): " & IsObj($oIE))

	If IsObj($oIE) = False Or $hGuiIEUI = "" Then
		_IE_EmbeddedSetBrowserEmulation()

		$oIE = _IECreateEmbedded()
		If @error Then
			GUICtrlSetState($idNewUI, $GUI_UNCHECKED)
			_NewUI()
			MsgBox($MB_ICONERROR, @ScriptName, "New UI (beta) failed to initialize." & @CRLF & @CRLF & "You have been reverted back to the normal UI.")

			Return
		EndIf

		; based on https://stackoverflow.com/a/32561014
		If RegRead("HKCU\SOFTWARE\StreamHelper\", "IEUI_IsMaximized") = 1 Then
			$iMaximized = True
		EndIf

		$hGuiIEUI = GUICreate("StreamHelper - Interface2", 800, 600, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS, $WS_CLIPCHILDREN))
		GUISetBkColor(0x1E1E1E)
		If @Compiled = False Then GUISetIcon(@ScriptDir & "\Svartnos.ico")

		GUICtrlCreateButton("Refresh", 20, 10, 100, 30)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		GUICtrlSetOnEvent(-1, _MAIN)
		GUICtrlCreateButton("Play from clipboard", 140, 10, 100, 30)
		GUICtrlSetResizing(-1, $GUI_DOCKALL)
		GUICtrlSetOnEvent(-1, _GuiShow)

		GUICtrlCreateButton("Settings", 330, 10, 100, 30)
		GUICtrlSetResizing(-1, $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKSIZE)
		GUICtrlSetOnEvent(-1, _SettingsShow)
		GUICtrlCreateButton("Send feedback", 450, 10, 100, 30)
		GUICtrlSetResizing(-1, $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKSIZE)
		GUICtrlSetOnEvent(-1, _FeedbackShow)
		GUICtrlCreateButton("About", 570, 10, 100, 30)
		GUICtrlSetResizing(-1, $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKSIZE)
		GUICtrlSetOnEvent(-1, _About)
		GUICtrlCreateButton("Exit", 690, 10, 100, 30)
		GUICtrlSetResizing(-1, $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKSIZE)
		GUICtrlSetOnEvent(-1, _Exit)

		GUICtrlCreateObj($oIE, 0, 50, 800, 550)
		GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)

		_IENavigate($oIE, "about:blank")

		Local $sBODY =	'<!DOCTYPE html>' & _
						'<!-- saved from url=(0014)about:internet -->' & _
						'<head>' & _
							'<meta http-equiv="X-UA-Compatible" content="IE=edge">' & _
							'<meta charset="utf-8">' & _
							'<link rel="stylesheet" href="' & @ScriptDir & '\interface2\interface2.css">' & _
						'</head>' & _
						'<body class="direction-ltr" style="overflow: hidden;">' & _
						'</body>' & _
						'</html>'
		_IEDocWriteHTML($oIE, $sBODY)

		GUISetOnEvent($GUI_EVENT_CLOSE, _IEUIHide)
		GUISetOnEvent($GUI_EVENT_RESIZED, _IEUIRefreshNoParam)
		GUISetOnEvent($GUI_EVENT_MAXIMIZE, _IEUIRefreshNoParam)
		GUISetOnEvent($GUI_EVENT_RESTORE, _IEUIRefreshNoParam)

		; based on https://stackoverflow.com/a/32561014
		If $iMaximized Then
			GUISetState(@SW_MAXIMIZE, $hGuiIEUI)
		Else
			GUISetState(@SW_SHOW, $hGuiIEUI)
			Local $sPosition = RegRead("HKCU\SOFTWARE\StreamHelper\", "IEUI_WindowPosition")
			If @error = 0 Then
				$asSplit = StringSplit($sPosition, "|")
				$tRECT = _WinAPI_CreateRectEx($asSplit[1], $asSplit[2], $asSplit[3], $asSplit[4])
				$hMonitor = _WinAPI_MonitorFromRect($tRECT, $MONITOR_DEFAULTTONULL)

				If $hMonitor <> 0 Then
					_GUIResizeClient($hGuiIEUI, $asSplit[1], $asSplit[2], $asSplit[3], $asSplit[4])
				EndIf
			EndIf
		EndIf
	Else
		GUISetState(@SW_SHOW, $hGuiIEUI)
	EndIf

	WinActivate($hGuiIEUI)
	_IEUIRefresh($oIE)
EndFunc

; based on https://www.autoitscript.com/forum/topic/122188-simple-form-resize-based-on-client-size/
Func _GUIResizeClient($hWnd, $iX, $iY, $iWidth, $iHeight)
	;$hWnd = Handle for the form to be resized
	;$iWidth = Desired X size for the client area
	;$iHeight = Desired Y size for the client area
	Local $winpos = WinGetPos($hWnd)
	Local $wincli = WinGetClientSize($hWnd)
	ConsoleWrite($iWidth & @CRLF)
	ConsoleWrite($winpos[2] & @CRLF)
	ConsoleWrite($wincli[0] & @CRLF)
	WinMove($hWnd, "", $iX, $iY, $iWidth + ($winpos[2]-$wincli[0]), $iHeight + ($winpos[3]-$wincli[1]))
EndFunc

Func _ObjDescription(ByRef $oObj, $msg = "") ; for debug purpose
	ConsoleWrite("--Debug:----------------------------------------------------------------------------" & @CRLF & _
			"[" & $msg & "]" & @CRLF)
	If IsObj($oObj) Then
		ConsoleWrite( _
			"The name of the Object:......................." & ObjName($oObj, $OBJ_NAME) & @CRLF & _
			"Description string of the Object:............." & ObjName($oObj, $OBJ_STRING) & @CRLF & _
			"The ProgID of the Object:....................." & ObjName($oObj, $OBJ_PROGID) & @CRLF & _
			"file associated with the obj in the Registry:." & ObjName($oObj, $OBJ_FILE) & @CRLF & _
			"Module name in which the object runs:........." & ObjName($oObj, $OBJ_MODULE) & @CRLF & _
			"CLSID of the object's coclass:................" & ObjName($oObj, $OBJ_CLSID) & @CRLF & _
			"IID of the object's interface:................" & ObjName($oObj, $OBJ_IID) & @CRLF)
	Else
		ConsoleWrite("Is not an object" & @CRLF)
	EndIf
EndFunc   ;==>_ObjDescription

Func _IEUIHide()
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "IEUI_IsMaximized", "REG_SZ", Number(BitAND(WinGetState($hGuiIEUI), $WIN_STATE_MAXIMIZED) = $WIN_STATE_MAXIMIZED))

	$aiPos = WinGetPos($hGuiIEUI)
	ReDim $aiPos[2]
	$aiSize = WinGetClientSize($hGuiIEUI)

	Local $aiCombined[0]
	_ArrayConcatenate($aiCombined, $aiPos)
	_ArrayConcatenate($aiCombined, $aiSize)

	RegWrite("HKCU\SOFTWARE\StreamHelper\", "IEUI_WindowPosition", "REG_SZ", _ArrayToString($aiCombined))

	GUIDelete($hGuiIEUI)
	$hGuiIEUI = ""
EndFunc

Func _IEUIRefreshNoParam()   ; workaround because GUISetOnEvent calls functions without params (even default ones)
	If $sNewUI Then _IEUIRefresh()
EndFunc

Func _IEUIRefresh($oObject = "")
	Static Local $oIE, $hThumbnailTimer = TimerInit(), $iCacheBuster = 0
	If IsObj($oObject) Then $oIE = $oObject

	_CW("_IEUIRefresh early return 1: " & String($oIE = "" Or $hGuiIEUI = ""))
	If $oIE = "" Or $hGuiIEUI = "" Then Return

	_CW("current state is: " & WinGetState($hGuiIEUI))
	_CW("_IEUIRefresh early return 2: " & String(BitAND(WinGetState($hGuiIEUI), $WIN_STATE_VISIBLE) <> $WIN_STATE_VISIBLE))
	If BitAND(WinGetState($hGuiIEUI), $WIN_STATE_VISIBLE) <> $WIN_STATE_VISIBLE Then Return
	_CW("generating IEUI")

	_CW("IEUI winhandle: " & String($hGuiIEUI))

	Local $oBody = _IETagNameGetCollection($oIE, "body", 0)
	Local $iWidth = _IEPropertyGet($oBody, "width")
	Local $iNewWidth = Floor($iWidth / 460) * 460
	Local $sBody =		'<div id="outer">' & _
						'<div id="inner" style="width: ' & $iNewWidth & 'px">'

	; Twitch caches thumbnails for 5 minutes, so we wait at least 5 min 1 sec
	If TimerDiff($hThumbnailTimer) > _Max($sRefreshMinutes * 60000, 301 * 1000) Then
		$hThumbnailTimer = TimerInit()
		$iCacheBuster += 1
	EndIf
	_CW("$iCacheBuster: " & $iCacheBuster)

	For $iX = UBound($aStreams) -1 To 0 Step -1
		If $aStreams[$iX][$eTrayId] = 0 Then ContinueLoop
		$sBody &=		'<div class="stream" data-index="' & $iX & '">'

		If $aStreams[$iX][$eFlags] = $eIsStream Then
			$sBody &=	'<div class="extra-buttons">'

			If StringInStr($asFavorites, $aStreams[$iX][$eUserID], $STR_CASESENSE) Then
				$sBody &=	'<button class="favorite" title="Remove favorite">♡</button>'
			Else
				$sBody &=	'<button class="favorite" title="Add to favorites">❤</button>'
			EndIf

			If $sStreamlinkEnabled = "1" Then
				$sBody &=	'<button class="streamlink" title="Open Streamlink window">Sl</button>'
			EndIf

			$sBody &=	'</div>'   ;close extra-buttons
		EndIf

		If $aStreams[$iX][$ePreview] <> "" Then
			$sBody &=	'<div class="item-image-container stream-preview">' & _
							'<img class="" alt="" src="' & StringReplace(StringReplace($aStreams[$iX][$ePreview], "{width}", 103), "{height}", 58) & "#" & $iCacheBuster & '">' & _
						'</div>'
		EndIf

		If $aStreams[$iX][$eName] <> "" Then
			$sBody &=	'<span class="stream-info stream-title">' & _
							$aStreams[$iX][$eName] & " (" & $aStreams[$iX][$eDisplayName] & ")" & _
						'</span>'
		Else
			$sBody &=	'<span class="stream-info stream-title">' & _
							$aStreams[$iX][$eDisplayName] & _
						'</span>'
		EndIf

		$sBody &=		'<span class="stream-info">' & _
							$aStreams[$iX][$eGame] & _
						'</span>' & _
						'<span class="stream-info" title="' & __WinHttpHTMLEncode($aStreams[$iX][$eStatus]) & '">' & _
							$aStreams[$iX][$eStatus] & _
						'</span>'

		$sBody &=		'<div class="services">'
		If $aStreams[$iX][$eFlags] = $eIsStream And $aStreams[$iX][$eService] = $eTwitch Then
			$sBody &=		'<img src="' & @ScriptDir & '\interface2\TwitchGlitchPurple.png' & '"/>'
		ElseIf $aStreams[$iX][$eService] = $eMixer Then
			$sBody &=		'<img src="' & @ScriptDir & '\interface2\MixerMerge_Dark.png' & '"/>'
		ElseIf $aStreams[$iX][$eFlags] = $eIsLink Then
			$sBody &=		'<img src="' & @ScriptDir & '\interface2\GitHub-Mark-Light-120px-plus.png' & '"/>'
		EndIf
		If $aStreams[$iX][$eFlags] = $eIsStream Then
			$sBody &=		'<span class="stream-info stats">' & _
								'Started ' & $aStreams[$iX][$eTime] & ' ago, ' & $aStreams[$iX][$eViewers] & ' viewers' & _
							'</span>'
		EndIf
		$sBody &=		'</div>'

		$sBody &=		'</div>'
	Next
	$sBody &=			'</div>' & _
						'</div>'

	_IEBodyWriteHTML($oIE, $sBody)

	Local $oElements = _IETagNameGetCollection($oIE, "DIV"), $iError = @error, $iExtended = @extended
	_CW("_IETagNameGetCollection @error: " & $iError)
	_CW("_IETagNameGetCollection @extended: " & $iExtended)

	; I was hoping that cleaning up the events would stop the slowly creeping memory usage but no...
	For $iX = 0 To UBound($aoEvents) -1
		$aoEvents[$iX].stop
		$aoEvents[$iX] = 0
	Next

	Global $aoEvents[0]
	For $oElement In $oElements
		If $oElement.className = "stream" Then
			ReDim $aoEvents[UBound($aoEvents) +1]
			$aoEvents[UBound($aoEvents) -1] = ObjEvent($oElement, "_IEEvent2_", "HTMLElementEvents2")
		EndIf
	Next
EndFunc

; based on __WinHttpHTMLDecode from WinHttp.au3
Func __WinHttpHTMLEncode($vData)
	Return StringReplace(StringReplace(StringReplace(StringReplace($vData, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), '"', "&quot;")
EndFunc

Volatile Func _IEEvent2_onClick($oEvent)
	Local $oElement = $oEvent.srcElement

	While 1
		If $oElement.className = "stream" Then
			Local $sIndex = $oElement.getAttribute('data-index'), $sUrl = $aStreams[$sIndex][$eUrl]

			If BitAND($aStreams[$sIndex][$eFlags], $eIsLink) = $eIsLink Then
				ShellExecute($aStreams[$sIndex][$eUrl])
			ElseIf BitAND($aStreams[$sIndex][$eFlags], $eIsText) = $eIsText Then
				Return
			ElseIf BitAND($aStreams[$sIndex][$eFlags], $eIsStream) = $eIsStream Then
				If $sStreamlinkEnabled = "1" Then
					_StreamlinkPlay($sUrl)
				Else
					ShellExecute($sUrl)
				EndIf
			EndIf

			$oEvent.cancelBubble = True
			Return
		ElseIf $oElement.className = "favorite" Then
			Local $sIndex = $oElement.parentElement.parentElement.getAttribute('data-index')

			Local $sUserID = $aStreams[$sIndex][$eUserID]

			If StringInStr($asFavorites, $sUserID, $STR_CASESENSE) Then   ; if fav then remove it from fav
				$asFavorites = StringReplace($asFavorites, $sUserID & @LF, "")
				RegDelete("HKCU\SOFTWARE\StreamHelper\Favorite\", $sUserID)
				$oElement.innerText = "❤"
				$oElement.setAttribute("title", "Add to favorites")
			Else   ; if nothing then fav
				$asFavorites &= $sUserID & @LF
				RegWrite("HKCU\SOFTWARE\StreamHelper\Favorite\", $sUserID, "REG_SZ", "")
				$oElement.innerText = "♡"
				$oElement.setAttribute("title", "Remove favorite")
			EndIf

			$oEvent.cancelBubble = True
			Return
		ElseIf $sStreamlinkEnabled = "1" And $oElement.className = "streamlink" Then
			Local $sIndex = $oElement.parentElement.parentElement.getAttribute('data-index')

			Local $asStream[] = [$aStreams[$sIndex][$eUrl], $aStreams[$sIndex][$eDisplayName]]
			_ClipboardGo($asStream)

			$oEvent.cancelBubble = True
			Return
		EndIf

		$oElement = $oElement.parentElement
	WEnd
EndFunc   ;==>_IEEvent2_onClick
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
	If @error Then Return $asInstallType[$eClassic]

	$aResult = DllCall("Kernel32.dll", "LONG", "GetPackageFamilyName", "handle", $hProcess, "uint*", 0, "wstr", Null)
	$iError = @error
	_WinAPI_CloseHandle($hProcess)
	If $iError Then Return $asInstallType[$eClassic]
	If $aResult[0] = $APPMODEL_ERROR_NO_PACKAGE Then Return $asInstallType[$eClassic]

	Return $asInstallType[$eAppX]
EndFunc

Func _CW($sMessage, $iReset = False)
	If IsArray($sMessage) Then $sMessage = _ArrayToString($sMessage, " :: ")
	ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & " " & $sMessage & @CRLF)

	If $sLog = 1 Then
		_DeleteOldLogs()

		Static Local $hLog = FileOpen(@LocalAppDataDir & "\StreamHelper\logs\log" & @YDAY & ".txt", $FO_APPEND + $FO_CREATEPATH)
		If $iReset Then
			FileClose($hLog)
			$hLog = FileOpen(@LocalAppDataDir & "\StreamHelper\logs\log" & @YDAY & ".txt", $FO_APPEND + $FO_CREATEPATH)
		EndIf

		If $hLog Then _FileWriteLog($hLog, $sMessage)
	EndIf
EndFunc

Func _Upgrade()
	If RegRead("HKCU\SOFTWARE\StreamHelper\", "Upgrade") = $sInternalVersion Then Return
	_1200()
	_1410()
	RegWrite("HKCU\SOFTWARE\StreamHelper\", "Upgrade", "REG_SZ", $sInternalVersion)
EndFunc

Func _1200()
	Local $sFavorites = RegRead("HKCU\SOFTWARE\StreamHelper\", "Favorites")
	If @error = 0 Then
		Local $asFavorites = StringSplit($sFavorites, @LF)
		For $iX = 1 To $asFavorites[0]
			RegWrite("HKCU\SOFTWARE\StreamHelper\Favorite\", $asFavorites[$iX], "REG_SZ", "")
		Next
		RegDelete("HKCU\SOFTWARE\StreamHelper\", "Favorites")
	EndIf

	Local $sIgnores = RegRead("HKCU\SOFTWARE\StreamHelper\", "Ignore")
	If @error = 0 Then
		Local $asIgnores = StringSplit($sIgnores, @LF)
		For $iX = 1 To $asIgnores[0]
			RegWrite("HKCU\SOFTWARE\StreamHelper\Ignore\", $asIgnores[$iX], "REG_SZ", "")
		Next
		RegDelete("HKCU\SOFTWARE\StreamHelper\", "Ignore")
	EndIf
EndFunc

Func _1410()
	RegDelete("HKCU\SOFTWARE\StreamHelper\", "TwitchFollowedGames")
	RegDelete("HKCU\SOFTWARE\StreamHelper\", "MigratedFavorites")
EndFunc

Func _EnumValues($sKey)
	Local $sKeyValue = "", $sValues

	For $iX = 1 To 9999
		$sKeyValue = RegEnumVal("HKCU\SOFTWARE\StreamHelper\" & $sKey, $iX)
		If @error Then ExitLoop
		$sValues &= $sKeyValue & @LF
	Next

	Return $sValues
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

Func _LogSize()
	$asLogs = _FileListToArray(@LocalAppDataDir & "\StreamHelper\logs", "log*.txt", $FLTA_FILES, True)
	If @error Then Return 0

	Local $iSize = 0
	For $iX = 1 To $asLogs[0]
		$iSize += FileGetSize($asLogs[$iX])
	Next

	Return Ceiling($iSize / 1048576)
EndFunc

Func _LogFolderOpen()
	ShellExecute(@LocalAppDataDir & "\StreamHelper\logs")
EndFunc

Func _LogFolderDelete()
	DirRemove(@LocalAppDataDir & "\StreamHelper\logs", $DIR_REMOVE)

	_CW("Deleted all(?) logs", True)
EndFunc

Func _StreamSet($sDisplayName, $sUrl, $sThumbnail, $sGame, $sCreated, $sTime, $sStatus, $iService, $iUserID, $sStreamID = 404, $iFlags = $eIsStream, $iGameID = "", $iViewers = Default, $iChannelID = "", $sName = Default)
	If $sDisplayName <> "" Then
		_CW("Found streamer: " & $sDisplayName)
	Else
		_CW("Found id: " & $iUserID)
	EndIf

	If $sStreamID = Default Then $sStreamID = 404
	If $iFlags = Default Then $iFlags = $eIsStream
	If $iGameID = Default Then $iGameID = ""
	If $iViewers = Default Then $iViewers = "?"
	If $iChannelID = Default Then $iChannelID = ""
	If $sName = Default Then $sName = ""

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

		If $aStreams[$iIndex][$eName] <> "" Then
			$sName = $aStreams[$iIndex][$eName]
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
	$aStreams[$iIndex][$eChannelID] = $iChannelID
	$aStreams[$iIndex][$eViewers] = $iViewers
	$aStreams[$iIndex][$eName] = $sName

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

	If $sStreamlinkEnabled = "0" Then Return $asError

	If Not _CanHandleURL($sUrl) Then Return $asError

	Local $sProgram = "streamlink.exe"
	If $sStreamlinkPath Then
		$sProgram = '"' & $sStreamlinkPath & '"'
	EndIf
	$sProgram &= " --twitch-disable-hosting"
	$sProgram &= " --json"
	$sProgram &= " " & $sUrl

	$iPID = Run($sProgram, "", @SW_HIDE, $STDOUT_CHILD)
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)

	_CW(StringStripWS($sOutput, $STR_STRIPALL))

	$oJSON = Json_Decode($sOutput)
	If IsObj($oJSON) = False Then Return $asError

	$aoStreams = Json_ObjGet($oJSON, "streams")
	If IsObj($aoStreams) = False Then Return $asError

	Local $asQualities[0]
	For $vItem In $aoStreams
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

Func _ArrayDebug()
	_ArrayDisplay($aStreams)
EndFunc

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
	If $wParam = 0x1234 And $lParam = 0xABCD Then Exit

	;Don't bother with the internal message handler since it's my own message
	Return
EndFunc

Func _WaitForInternet()
	If _WinAPI_IsInternetConnected() Then
		AdlibUnRegister(_WaitForInternet)
		_MAIN()
	EndIf
EndFunc

Func _OtherSet($sText, $iFlags, $sUrl = "", $sGame = "", $sTitle = "")
	$hTray = TrayItemGetHandle(0)
	$iCount = _GUICtrlMenu_GetItemCount($hTray)
	ReDim $aStreams[UBound($aStreams) +1][$eMax]
	$aStreams[UBound($aStreams) -1][$eDisplayName] = $sText
	$aStreams[UBound($aStreams) -1][$eTrayId] = TrayCreateItem($sText, -1, $iCount -3)
	$aStreams[UBound($aStreams) -1][$eFlags] = $iFlags
	If $sUrl <> "" Then $aStreams[UBound($aStreams) -1][$eUrl] = $sUrl
	If $sGame <> "" Then $aStreams[UBound($aStreams) -1][$eGame] = $sGame
	If $sTitle <> "" Then $aStreams[UBound($aStreams) -1][$eStatus] = $sTitle
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
	If _InstallType() = $asInstallType[$eAppX] Then Return

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

	If Json_IsObject($oJSON) = False Then
		_OtherSet("Update check failed", $eIsText)
		Return
	EndIf

	$sTag = Json_ObjGet($oJSON, "tag_name")
	If StringIsDigit(StringLeft($sTag, 1)) = False Then $sTag = StringTrimLeft($sTag, 1)   ;remove the "v" in front of versions

	If _VersionCompare($sInternalVersion, $sTag) = -1 Then   ;if github is greater
		_OtherSet("Update found! Click to open website", $eIsLink, "https://github.com/TzarAlkex/StreamHelper/releases", "Newest version is " & $sTag, "You are running " & $sInternalVersion)
		TrayItemSetOnEvent(-1, _TrayStuff)
		Return
	EndIf
EndFunc
#EndRegion
