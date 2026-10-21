#Requires AutoHotkey v2.0 64-bit
#SingleInstance Force

; Hold either Windows key and tap Tab to cycle desktops in Task View order.
; Switch directly, including when wrapping from the last desktop to the first.
; Uses https://github.com/Ciantic/VirtualDesktopAccessor

; Win+Shift+Tab opens the normal Windows Task View.
$#+Tab::Send("#{Tab}")

$#Tab:: {
	try {
		SwitchDesktop()
	} catch Error as err {
		ToolTip("DesktopSwitcher: " err.Message)
		SetTimer(() => ToolTip(), -3000)
	} finally {
		; Keep a held Tab key from cycling repeatedly.
		KeyWait("Tab")
	}
}

SwitchDesktop() {
	api := GetDesktopApi()
	state := GetDesktopState()
	if (state.Count = 1) {
		return
	}

	; VirtualDesktopAccessor uses zero-based desktop numbers.
	nextIndex := Mod(state.Index + 1, state.Count)
	if (DllCall(api.GoToDesktopNumber, "Int", nextIndex, "Int") = -1) {
		throw Error("Windows could not switch desktops.")
	}

	; Explorer processes desktop switches asynchronously.
	deadline := A_TickCount + 1500
	while (GetDesktopState().Index != nextIndex) {
		if (A_TickCount >= deadline) {
			throw Error("Windows did not finish switching desktops.")
		}
		Sleep(25)
	}
}

GetDesktopState() {
	api := GetDesktopApi()
	count := DllCall(api.GetDesktopCount, "Int")
	index := DllCall(api.GetCurrentDesktopNumber, "Int")
	if (count < 1 || index < 0 || index >= count) {
		throw Error("Could not read Windows desktops. VirtualDesktopAccessor requires Windows build 26100.2605 or newer.")
	}

	return {Index: index, Count: count}
}

GetDesktopApi() {
	static api := LoadDesktopApi()
	return api
}

LoadDesktopApi() {
	directory := A_ScriptDir "\lib"
	tempDirectory := ""
	module := 0
	try {
		if A_IsCompiled {
			; Embed the DLL so the executable can also run alone from Startup.
			tempDirectory := A_Temp "\DesktopSwitcher-" DllCall("GetCurrentProcessId", "UInt") "-" A_TickCount
			directory := tempDirectory
			DirCreate(directory)
			FileInstall("lib\VirtualDesktopAccessor.dll", directory "\VirtualDesktopAccessor.dll")
			FileInstall("lib\VirtualDesktopAccessor.LICENSE.txt", directory "\VirtualDesktopAccessor.LICENSE.txt")
		}

		; Load only this DLL and dependencies from its directory or System32.
		module := DllCall("LoadLibraryExW", "Str", directory "\VirtualDesktopAccessor.dll", "Ptr", 0, "UInt", 0x900, "Ptr")
		if !module {
			throw Error("Could not load VirtualDesktopAccessor.dll. Windows error " A_LastError ". Restore ahk\lib, then rebuild if using the executable.")
		}

		api := {}
		for name in ["GetDesktopCount", "GetCurrentDesktopNumber", "GoToDesktopNumber"] {
			address := DllCall("GetProcAddress", "Ptr", module, "AStr", name, "Ptr")
			if !address {
				throw Error("VirtualDesktopAccessor.dll is missing " name ".")
			}
			api.%name% := address
		}

		OnExit((*) => UnloadDesktopApi(module, tempDirectory))
		return api
	} catch {
		UnloadDesktopApi(module, tempDirectory)
		throw
	}
}

UnloadDesktopApi(module, tempDirectory) {
	if module {
		DllCall("FreeLibrary", "Ptr", module)
	}
	if (tempDirectory != "") {
		try FileDelete(tempDirectory "\VirtualDesktopAccessor.dll")
		try FileDelete(tempDirectory "\VirtualDesktopAccessor.LICENSE.txt")
		try DirDelete(tempDirectory)
	}
}

