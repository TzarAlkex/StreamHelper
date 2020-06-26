#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         Alexander Samuelsson

 Script Function:
	CentennialHelper.dll UDF

#ce ----------------------------------------------------------------------------

;~ CreationCollisionOption
Global Enum $eGenerateUniqueName, $eReplaceExisting, $eFailIfExists, $eOpenIfExists

;~ StartupTaskState
Global Enum $eStateError = -1, $eStateDisabled, $eStateDisabledByUser, $eStateEnabled, $eStateDisabledByPolicy, $eStateEnabledByPolicy

Global $hDLL = DllOpen(@ScriptDir & "\CentennialHelper.dll")


Func _LocalCacheFolder()
	Return DllCall($hDLL, "WSTR:cdecl", "ApplicationDataLocalCacheFolder")
EndFunc

Func _LocalFolder()
	Return DllCall($hDLL, "WSTR:cdecl", "ApplicationDataLocalFolder")
EndFunc


Func _LocalDeleteContainer($sContainer)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataLocalDeleteContainer", "WSTR", $sContainer)
EndFunc

Func _LocalExistContainer($sContainer)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataLocalExistContainer", "WSTR", $sContainer)
EndFunc


Func _LocalSettingsExist($sSetting, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataLocalSettingsExist", "WSTR", $sSetting, "WSTR", $sContainer)
EndFunc

Func _LocalSettingsInsert($sSetting, $sValue, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataLocalSettingsInsert", "WSTR", $sSetting, "WSTR", $sValue, "WSTR", $sContainer)
EndFunc

Func _LocalSettingsRemove($sSetting, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataLocalSettingsRemove", "WSTR", $sSetting, "WSTR", $sContainer)
EndFunc

Func _LocalSettingsValues($hCallback, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataLocalSettingsValues", "PTR", DllCallbackGetPtr($hCallback), "WSTR", $sContainer)
EndFunc


Func _RoamingDataChanged($hCallback)
	Return DllCall($hDLL, "NONE:cdecl", "ApplicationDataRoamingDataChanged", "PTR", DllCallbackGetPtr($hCallback))
EndFunc

Func _RoamingFolder()
	Return DllCall($hDLL, "WSTR:cdecl", "ApplicationDataRoamingFolder")
EndFunc

Func _RoamingFolderWrite($sFileName, $iFileOption, $sValue)
	Return DllCall($hDLL, "NONE:cdecl", "ApplicationDataRoamingFolderWrite", "WSTR", $sFileName, "INT", $iFileOption, "WSTR", $sValue)
EndFunc

Func _RoamingStorageQuota()
	Return DllCall($hDLL, "UINT64:cdecl", "ApplicationDataRoamingStorageQuota")
EndFunc


Func _RoamingDeleteContainer($sContainer)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataRoamingDeleteContainer", "WSTR", $sContainer)
EndFunc

Func _RoamingExistContainer($sContainer)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataRoamingExistContainer", "WSTR", $sContainer)
EndFunc


Func _RoamingSettingsExist($sSetting, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataRoamingSettingsExist", "WSTR", $sSetting, "WSTR", $sContainer)
EndFunc

Func _RoamingSettingsInsert($sSetting, $sValue, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataRoamingSettingsInsert", "WSTR", $sSetting, "WSTR", $sValue, "WSTR", $sContainer)
EndFunc

Func _RoamingSettingsRemove($sSetting, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataRoamingSettingsRemove", "WSTR", $sSetting, "WSTR", $sContainer)
EndFunc

Func _RoamingSettingsValues($hCallback, $sContainer = Null)
	Return DllCall($hDLL, "BOOLEAN:cdecl", "ApplicationDataRoamingSettingsValues", "PTR", DllCallbackGetPtr($hCallback), "WSTR", $sContainer)
EndFunc


Func _TemporaryFolder()
	Return DllCall($hDLL, "WSTR:cdecl", "ApplicationDataTemporaryFolder")
EndFunc


Func _StartupTaskDisable()
	Return DllCall($hDLL, "INT:cdecl", "StartupTaskDisable")
EndFunc

Func _StartupTaskEnable()
	Return DllCall($hDLL, "INT:cdecl", "StartupTaskEnable")
EndFunc

;~ Func _StartupTaskStatus()
;~ 	ConsoleWrite("not working" & @CRLF)
;~ 	MsgBox()
;~ 	Exit
;~ 	Return DllCall($hDLL, "INT:cdecl", "StartupTaskStatus")
;~ EndFunc

Func _StartupTaskStatusByID($sTaskID)
	Return DllCall($hDLL, "INT:cdecl", "StartupTaskStatusByID", "WSTR", $sTaskID)
EndFunc

Func _StartupTaskStatusByIndex($iTaskIndex)
	Return DllCall($hDLL, "INT:cdecl", "StartupTaskStatusByIndex", "INT", $iTaskIndex)
EndFunc