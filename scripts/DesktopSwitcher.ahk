#Requires AutoHotkey v2.0
#SingleInstance Force

; Hold either Windows key and tap Tab to cycle desktops in Task View order.
; shortcut: wrapping crosses intermediate desktops, use a shell API for direct jumps.
; Desktop registry layout: https://github.com/pmb6tz/windows-desktop-switcher

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
	state := GetDesktopState()
	if (state.Count = 1) {
		return
	}

	wrapping := state.Index = state.Count
	steps := wrapping ? state.Count - 1 : 1

	Loop steps {
		expectedIndex := wrapping ? state.Index - A_Index : state.Index + 1
		Send(wrapping ? "#^{Left}" : "#^{Right}")

		; Explorer processes desktop switches asynchronously.
		deadline := A_TickCount + 1500
		while (GetDesktopState().Index != expectedIndex) {
			if (A_TickCount >= deadline) {
				throw Error("Windows did not finish switching desktops.")
			}
			Sleep(25)
		}
		Sleep(150)
	}
}

GetDesktopState() {
	key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops"
	ids := RegRead(key, "VirtualDesktopIDs")
	currentId := RegRead(key, "CurrentVirtualDesktop", "")

	; Windows 10 stores the current desktop under the Windows session instead.
	if (currentId = "") {
		sessionId := 0
		if !DllCall("ProcessIdToSessionId", "UInt", DllCall("GetCurrentProcessId", "UInt"), "UInt*", &sessionId) {
			throw OSError()
		}
		key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\" sessionId "\VirtualDesktops"
		currentId := RegRead(key, "CurrentVirtualDesktop")
	}

	return ParseDesktopState(ids, currentId)
}

ParseDesktopState(ids, currentId) {
	; RegRead returns each 16-byte desktop GUID as 32 hexadecimal characters.
	if (StrLen(currentId) != 32 || StrLen(ids) = 0 || Mod(StrLen(ids), 32)) {
		throw Error("Windows returned an invalid desktop list.")
	}

	count := StrLen(ids) // 32
	Loop count {
		if (SubStr(ids, (A_Index - 1) * 32 + 1, 32) = currentId) {
			return {Index: A_Index, Count: count}
		}
	}

	throw Error("The current desktop is missing from Windows' desktop list.")
}

