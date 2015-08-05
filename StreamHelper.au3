#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.0.0.13
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: SOME VERSION WITH MAPS (Beta)
 Author:         Alexander Samuelsson AKA AdmiralAlkex

 Script Function:
	Stuff

#ce ----------------------------------------------------------------------------

$sTwitchUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Twitch", "")   ;NAME ON TWITCH
$sHitboxUsername = IniRead(@ScriptDir & "\Settings.ini", "Section", "Hitbox", "")   ;NAME ON HITBOX
$iMinRefresh = IniRead(@ScriptDir & "\Settings.ini", "Section", "RefreshMinutes", 5)   ;HOW MANY MINUTES BETWEEN EVERY CHECK FOR NEW STREAMS

Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

#include <AutoItConstants.au3>
#include "Json.au3"
#include <Array.au3>
#include <InetConstants.au3>
#include <Date.au3>

Local $idTwitch = TrayCreateMenu("Twitch")
TrayCreateItem("")

Local $idHitbox = TrayCreateMenu("Hitbox")
TrayCreateItem("")

Local $idRefresh = TrayCreateItem("Manual Refresh")
TrayItemSetOnEvent( -1, _TrayStuff)
TrayCreateItem("")

Local $idAbout = TrayCreateItem("About")
TrayItemSetOnEvent( -1, _TrayStuff)
TrayCreateItem("")

Local $idExit = TrayCreateItem("Exit")
TrayItemSetOnEvent( -1, _TrayStuff)

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime

Global $sNew
Global $mTwitch[]
Global $mHitbox[]

Global $iLivestreamerInstalled = StringInStr(EnvGet("path"), "Livestreamer") > 0

AdlibRegister(PostLaunchInitializer)

While 1
	Global $sNew = ""
	If $sTwitchUsername <> "" Then _Twitch()
	If $sHitboxUsername <> "" Then _Hitbox()

	If $sNew <> "" Then TrayTip("Now streaming", $sNew, 10)

	Global $iTimer = TimerInit()

	Do
		Sleep(2000)
	Until TimerDiff($iTimer) > $iMinRefresh * 60000
WEnd

#Region TWITCH
Func _Twitch()
	ConsoleWrite("Twitching" & @CRLF)
	_TwitchGet($sTwitchUsername)

	Local $aMapKeys = MapKeys($mTwitch)
	For $iX = 0 To UBound($aMapKeys) -1
		ConsoleWrite($aMapKeys[$iX] & @CRLF)

		If $mTwitch[$aMapKeys[$iX]].Online = True Then
			If $mTwitch[$aMapKeys[$iX]].TrayId = 0 Then
				$mTwitch[$aMapKeys[$iX]].TrayId = TrayCreateItem($aMapKeys[$iX] & " | " & $mTwitch[$aMapKeys[$iX]].Game, $idTwitch)
				TrayItemSetOnEvent( -1, _TrayStuff)

				$sNew &= $aMapKeys[$iX] & " | " & $mTwitch[$aMapKeys[$iX]].Game & @CRLF
			Else
				TrayItemSetText($mTwitch[$aMapKeys[$iX]].TrayId, $aMapKeys[$iX] & " | " & $mTwitch[$aMapKeys[$iX]].Game)
			EndIf
			$mTwitch[$aMapKeys[$iX]].Online = False
		Else
			If $mTwitch[$aMapKeys[$iX]].TrayId <> 0 Then
				TrayItemDelete($mTwitch[$aMapKeys[$iX]].TrayId)
				$mTwitch[$aMapKeys[$iX]].TrayId = 0
			EndIf
		EndIf
	Next
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

		For $iX = 0 To UBound($avTemp) -1
			ConsoleWrite($iX +1 & "/" & UBound($avTemp) & @CRLF)

			$oChannel = Json_ObjGet($avTemp[$iX], "channel")
			$sName = Json_ObjGet($oChannel, "name")
			$sOptions = '?channel=' & ',' & $sName
			$sUrl = "https://api.twitch.tv/kraken/" & "streams" & $sOptions
			$oChannel = FetchItems($sUrl, "streams")

			If IsArray($oChannel) Then

				$oChannel2 = Json_ObjGet($oChannel[0], "channel")
				$sUrl = Json_ObjGet($oChannel2, "url")
				If $sUrl = "" Then $sUrl = "http://www.twitch.tv/" & Json_ObjGet($oChannel2, "name")

				$sDisplayName = Json_ObjGet($oChannel2, "display_name")

				$sStatus = Json_ObjGet($oChannel2, "status")

				$oPreview = Json_ObjGet($oChannel[0], "preview")
				$sMedium = Json_ObjGet($oPreview, "medium")

				$sGame = Json_ObjGet($oChannel[0], "game")

				$sCreated = Json_ObjGet($oChannel[0], "created_at")

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

				ConsoleWrite("Found streamer: " & $sDisplayName & @CRLF)

				If MapExists($mTwitch, $sDisplayName) Then
					$mTwitch[$sDisplayName].Game = $sGame
					$mTwitch[$sDisplayName].Created = $sCreated
					$mTwitch[$sDisplayName].Time = $sTime
					$mTwitch[$sDisplayName].Status = $sStatus
					$mTwitch[$sDisplayName].Online = True
				Else
					Local $mInternal[]
					$mInternal.Url = $sUrl
					$mInternal.Preview = $sMedium
					$mInternal.Game = $sGame
					$mInternal.Created = $sCreated
					$mInternal.Time = $sTime
					$mInternal.Status = $sStatus
					$mInternal.Online = True
					$mInternal.TrayId = 0

					$mTwitch[$sDisplayName] = $mInternal
				EndIf

			EndIf
		Next

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
	_HitboxGet($sHitboxUsername)

	Local $aMapKeys = MapKeys($mHitbox)
	For $iX = 0 To UBound($aMapKeys) -1
		ConsoleWrite($aMapKeys[$iX] & @CRLF)

		If $mHitbox[$aMapKeys[$iX]].Online = True Then
			If $mHitbox[$aMapKeys[$iX]].TrayId = 0 Then
				$mHitbox[$aMapKeys[$iX]].TrayId = TrayCreateItem($aMapKeys[$iX] & " | " & $mHitbox[$aMapKeys[$iX]].Game, $idHitbox)
				TrayItemSetOnEvent( -1, _TrayStuff)

				$sNew &= $aMapKeys[$iX] & " | " & $mHitbox[$aMapKeys[$iX]].Game & @CRLF
			Else
				TrayItemSetText($mHitbox[$aMapKeys[$iX]].TrayId, $aMapKeys[$iX] & " | " & $mHitbox[$aMapKeys[$iX]].Game)
			EndIf
			$mHitbox[$aMapKeys[$iX]].Online = False
		Else
			If $mHitbox[$aMapKeys[$iX]].TrayId <> 0 Then
				TrayItemDelete($mHitbox[$aMapKeys[$iX]].TrayId)
				$mHitbox[$aMapKeys[$iX]].TrayId = 0
			EndIf
		EndIf
	Next
EndFunc

Func _HitboxGet($sUsername)
	$iLimit = 100
	$iOffset = 0
	$sQuotedUsername = URLEncode($sUsername)
	$sBaseUrl = "https://api.hitbox.tv/following/user?user_name=" & $sQuotedUsername

	While True
		$sUrl = $sBaseUrl & OPTIONS_OFFSET_LIMIT_HITBOX($iOffset, $iLimit)
		$avTemp = FetchItems($sUrl, "following")
		If UBound($avTemp) = 0 Then ExitLoop

		For $iX = 0 To UBound($avTemp) -1
			ConsoleWrite($iX +1 & "/" & UBound($avTemp) & @CRLF)

			$sUserName = Json_ObjGet($avTemp[$iX], "user_name")
			$sUrl = "https://api.hitbox.tv/media/live/" & $sUserName
			$oLivestream = FetchItems($sUrl, "livestream")

			If UBound($oLivestream) = 0 Then ContinueLoop

			If Json_ObjGet($oLivestream[0], "media_is_live") = 1 Then
				$oChannel = Json_ObjGet($oLivestream[0], "channel")
				$sUrl = Json_ObjGet($oChannel, "channel_link")

				$sDisplayName = Json_ObjGet($oLivestream[0], "media_display_name")

				$sStatus = Json_ObjGet($oLivestream[0], "media_status")

				$sThumbnail = Json_ObjGet($oLivestream[0], "media_thumbnail")

				$sGame = Json_ObjGet($oLivestream[0], "category_name")

				$sCreated = Json_ObjGet($oLivestream[0], "media_live_since")

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

				ConsoleWrite("Found streamer: " & $sDisplayName & @CRLF)

				If MapExists($mHitbox, $sDisplayName) Then
					$mHitbox[$sDisplayName].Game = $sGame
					$mHitbox[$sDisplayName].Created = $sCreated
					$mHitbox[$sDisplayName].Time = $sTime
					$mHitbox[$sDisplayName].Status = $sStatus
					$mHitbox[$sDisplayName].Online = True
				Else
					Local $mInternal[]
					$mInternal.Url = $sUrl
					$mInternal.Preview = $sThumbnail
					$mInternal.Game = $sGame
					$mInternal.Created = $sCreated
					$mInternal.Time = $sTime
					$mInternal.Status = $sStatus
					$mInternal.Online = True
					$mInternal.TrayId = 0

					$mHitbox[$sDisplayName] = $mInternal
				EndIf

			EndIf
		Next

		$iOffset += $iLimit
	WEnd
	Return "Potato on a Stick"
EndFunc

Func OPTIONS_OFFSET_LIMIT_HITBOX($iOffset, $iLimit)
	Return '&offset=' & $iOffset & '&limit=' & $iLimit
EndFunc
#EndRegion

#Region COMMON
Func FetchItems($sUrl, $sKey)
	$oJSON = getJson($sUrl)

	If IsObj($oJSON) = False Then Return ""

	$oFollows = Json_ObjGet($oJSON, $sKey)

	If UBound($oFollows) > 0 Then
		Return $oFollows
	Else
		Return ""
	EndIf
EndFunc

Func getJson($sUrl)
	$dJsonString = InetRead($sUrl, $INET_FORCERELOAD)

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
Func _TrayStuff()
	Switch @TRAY_ID
		Case $idAbout
			Local $asText[] = ["I am unfinished", "Ouch", "Quit poking me!", "Bewbs", "Pizza", "25W lightbulb (broken)", "Estrellas Salt & Vinäger chips är godast", "Vote Pewdiepie for King of Sweden", "Vote Robbaz for King of Sweden", "Vote Anderz for King of Sweden", "I'm sorry trancexx", "Vote Knugen for King of Sweden", '"Is it creepy that I follow you, should I stop doing it?" -Xandy', '"I can''t be expected to perform under pressure!" -jaberwacky', '"The square root of 76 is brown" -One F Jef']
			MsgBox(0, @ScriptName, "Add text here" & @CRLF & @CRLF & "Created by Alexander Samuelsson AKA AdmiralAlkex" & @CRLF & @CRLF & $asText[Random(0, UBound($asText) -1, 1)])
		Case $idRefresh
			$iTimer = 0
		Case $idExit
			Exit
		Case Else
			Local $sUrl
			Do
				Local $aMapKeys = MapKeys($mTwitch)
				For $iX = 0 To UBound($aMapKeys) -1
					If $mTwitch[$aMapKeys[$iX]].TrayId = @TRAY_ID Then
						$sUrl = $mTwitch[$aMapKeys[$iX]].Url
						ExitLoop 2
					EndIf
				Next
				Local $aMapKeys = MapKeys($mHitbox)
				For $iX = 0 To UBound($aMapKeys) -1
					If $mHitbox[$aMapKeys[$iX]].TrayId = @TRAY_ID Then
						$sUrl = $mHitbox[$aMapKeys[$iX]].Url
						ExitLoop 2
					EndIf
				Next
			Until False
			If $iLivestreamerInstalled Then
				Run("livestreamer " & $sUrl & " best", "", @SW_HIDE)
			Else
				ShellExecute($sUrl)
			EndIf
	EndSwitch
EndFunc
#EndRegion GUI

#Region INTENRAL INTERLECT
Func PostLaunchInitializer()
	AdlibUnRegister(PostLaunchInitializer)
EndFunc
#EndRegion