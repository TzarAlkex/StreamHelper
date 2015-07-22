#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Fileversion=0.0.0.13
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0 (Stable)
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
#include "JSMN.au3"
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

Global Enum $eDisplayName, $eUrl, $ePreview, $eGame, $eCreated, $eTrayId, $eStatus, $eTime, $eMax

Global $sNew
Global $asTwitch[1][$eMax]
Global $asHitbox[1][$eMax]

Global $iPID

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
	Local $asTwitchOld = $asTwitch
	$asTwitch = _TwitchGet($sTwitchUsername)

	If UBound($asTwitchOld, 0) = 2 Then
		For $iX = 0 To UBound($asTwitchOld) -1
			TrayItemDelete($asTwitchOld[$iX][$eTrayId])
		Next
	EndIf

	For $iX = 0 To UBound($asTwitch) -1
		$asTwitch[$iX][$eTrayId] = TrayCreateItem($asTwitch[$iX][$eDisplayName] & " | " & $asTwitch[$iX][$eGame], $idTwitch)
		TrayItemSetOnEvent( -1, _TrayStuff)

		_ArraySearch($asTwitchOld, $asTwitch[$iX][$eDisplayName])
		If @error = 6 Then $sNew &= $asTwitch[$iX][$eDisplayName] & " | " & $asTwitch[$iX][$eGame] & @CRLF
	Next
EndFunc

Func _TwitchGet($sUsername)
	Local $avRet[0][$eMax]
	$iLimit = 100
	$iOffset = 0
	$sQuotedUsername = URLEncode($sUsername)
	$sBaseUrl = "https://api.twitch.tv/kraken/users/" & $sQuotedUsername & "/follows/channels"
	While True
		$sUrl = $sBaseUrl & OPTIONS_OFFSET_LIMIT($iOffset, $iLimit)
		$avTemp = FetchItems($sUrl, "follows")
		If UBound($avTemp) = 0 Then ExitLoop

		For $iX = 0 To UBound($avTemp) -1
			ConsoleWrite($iX +1 & "/" & UBound($avTemp) & @CRLF)

			$oChannel = Jsmn_ObjGet($avTemp[$iX], "channel")
			$sName = Jsmn_ObjGet($oChannel, "name")
			$sOptions = '?channel=' & ',' & $sName
			$sUrl = "https://api.twitch.tv/kraken/" & "streams" & $sOptions
			$oChannel = FetchItems($sUrl, "streams")

			If IsArray($oChannel) Then

				$oChannel2 = Jsmn_ObjGet($oChannel[0], "channel")
				$sUrl = Jsmn_ObjGet($oChannel2, "url")
				If $sUrl = "" Then $sUrl = "http://www.twitch.tv/" & Jsmn_ObjGet($oChannel2, "name")

				$sDisplayName = Jsmn_ObjGet($oChannel2, "display_name")

				$sStatus = Jsmn_ObjGet($oChannel2, "status")

				$oPreview = Jsmn_ObjGet($oChannel[0], "preview")
				$sMedium = Jsmn_ObjGet($oPreview, "medium")

				$sGame = Jsmn_ObjGet($oChannel[0], "game")

				$sCreated = Jsmn_ObjGet($oChannel[0], "created_at")

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

				ReDim $avRet[UBound($avRet, 1) +1][UBound($avRet, 2)]
				$avRet[UBound($avRet) -1][$eDisplayName] = $sDisplayName
				$avRet[UBound($avRet) -1][$eUrl] = $sUrl
				$avRet[UBound($avRet) -1][$ePreview] = $sMedium
				$avRet[UBound($avRet) -1][$eGame] = $sGame
				$avRet[UBound($avRet) -1][$eCreated] = $sCreated
				$avRet[UBound($avRet) -1][$eTime] = $sTime
				$avRet[UBound($avRet) -1][$eStatus] = $sStatus
			EndIf
		Next

		$iOffset += $iLimit
	WEnd
	Return $avRet
EndFunc

Func FetchItems($sUrl, $sKey)
	$oJSON = getJson($sUrl)

;~ 	ConsoleWrite($sUrl & @CRLF)
;~ 	ConsoleWrite(VarGetType($oJSON) & @CRLF)
;~ 	ConsoleWrite($oJSON & @CRLF)

;~ 	ConsoleWrite("bla" & @CRLF)
	If VarGetType($oJSON) = "String" And $oJSON = "" Then Return ""
;~ 	ConsoleWrite("pizza" & @CRLF)

	$oFollows = Jsmn_ObjGet($oJSON, $sKey)

	If UBound($oFollows) > 0 Then
		Return $oFollows
	Else
		Return ""
	EndIf
EndFunc

Func getJson($sUrl)
	$dJsonString = InetRead($sUrl, $INET_FORCERELOAD)

	$oJSON = Jsmn_Decode(BinaryToString($dJsonString))
	Return $oJSON
EndFunc

Func OPTIONS_OFFSET_LIMIT($iOffset, $iLimit)
	Return '?offset=' & $iOffset & '&limit=' & $iLimit
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
#EndRegion TWITCH

#Region HITBOX
Func _Hitbox()
	ConsoleWrite("Hitboxing" & @CRLF)
	Local $asHitboxOld = $asHitbox
	$asHitbox = _HitboxGet($sHitboxUsername)

	If UBound($asHitboxOld, 0) = 2 Then
		For $iX = 0 To UBound($asHitboxOld) -1
			TrayItemDelete($asHitboxOld[$iX][$eTrayId])
		Next
	EndIf

	For $iX = 0 To UBound($asHitbox) -1
		$asHitbox[$iX][$eTrayId] = TrayCreateItem($asHitbox[$iX][$eDisplayName] & " | " & $asHitbox[$iX][$eGame], $idHitbox)
		TrayItemSetOnEvent( -1, _TrayStuff)

		_ArraySearch($asHitboxOld, $asHitbox[$iX][$eDisplayName])
		If @error = 6 Then $sNew &= $asHitbox[$iX][$eDisplayName] & " | " & $asHitbox[$iX][$eGame] & @CRLF
	Next
EndFunc

Func _HitboxGet($sUsername)
	Local $avRet[0][$eMax]
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

			$sUserName = Jsmn_ObjGet($avTemp[$iX], "user_name")
			$sUrl = "https://api.hitbox.tv/media/live/" & $sUserName
;~ 		ConsoleWrite("hej" & @CRLF)
			$oLivestream = FetchItems($sUrl, "livestream")
;~ 		ConsoleWrite("d�" & @CRLF)

			If UBound($oLivestream) = 0 Then ContinueLoop

			If Jsmn_ObjGet($oLivestream[0], "media_is_live") = 1 Then

				$oChannel = Jsmn_ObjGet($oLivestream[0], "channel")
				$sUrl = Jsmn_ObjGet($oChannel, "channel_link")

				$sDisplayName = Jsmn_ObjGet($oLivestream[0], "media_display_name")

				$sStatus = Jsmn_ObjGet($oLivestream[0], "media_status")

				$sThumbnail = Jsmn_ObjGet($oLivestream[0], "media_thumbnail")

				$sGame = Jsmn_ObjGet($oLivestream[0], "category_name")

				$sCreated = Jsmn_ObjGet($oLivestream[0], "media_live_since")

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

				ReDim $avRet[UBound($avRet, 1) +1][UBound($avRet, 2)]
				$avRet[UBound($avRet) -1][$eDisplayName] = $sDisplayName
				$avRet[UBound($avRet) -1][$eUrl] = $sUrl
				$avRet[UBound($avRet) -1][$ePreview] = $sThumbnail
				$avRet[UBound($avRet) -1][$eGame] = $sGame
				$avRet[UBound($avRet) -1][$eCreated] = $sCreated
				$avRet[UBound($avRet) -1][$eTime] = $sTime
				$avRet[UBound($avRet) -1][$eStatus] = $sStatus
			EndIf
		Next

		$iOffset += $iLimit
	WEnd
	Return $avRet
EndFunc

Func OPTIONS_OFFSET_LIMIT_HITBOX($iOffset, $iLimit)
	Return '&offset=' & $iOffset & '&limit=' & $iLimit
EndFunc
#EndRegion

#Region GUI
Func _TrayStuff()
	Switch @TRAY_ID
		Case $idAbout
			Local $asText[] = ["I am unfinished", "Ouch", "Quit poking me!", "Bewbs", "Pizza", "25W lightbulb (broken)", "Estrellas Salt & Vin�ger chips �r godast", "Vote Pewdiepie for King of Sweden", "Vote Robbaz for King of Sweden", "Vote Anderz for King of Sweden", "I'm sorry trancexx", "Vote Knugen for King of Sweden"]
			MsgBox(0, @ScriptName, "Add text here" & @CRLF & @CRLF & "Created by Alexander Samuelsson AKA AdmiralAlkex" & @CRLF & @CRLF & $asText[Random(0, UBound($asText) -1, 1)])
		Case $idRefresh
			$iTimer = 0
		Case $idExit
			Exit
		Case Else
			Do
				For $iX = 0 To UBound($asTwitch) -1
					If $asTwitch[$iX][$eTrayId] = @TRAY_ID Then
						$iPID = Run("livestreamer " & $asTwitch[$iX][$eUrl] & " best", "", @SW_HIDE)
						ExitLoop 2
					EndIf
				Next
				For $iX = 0 To UBound($asHitbox) -1
					If $asHitbox[$iX][$eTrayId] = @TRAY_ID Then
						$iPID = Run("livestreamer " & $asHitbox[$iX][$eUrl] & " best", "", @SW_HIDE)
						ExitLoop 2
					EndIf
				Next
			Until False
	EndSwitch
EndFunc
#EndRegion GUI