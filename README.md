# AutoHotkey scripts

Small Windows automation scripts written in AutoHotkey v2.

## Desktop switcher

[`scripts/DesktopSwitcher.ahk`](scripts/DesktopSwitcher.ahk) replaces **Win+Tab** with virtual desktop switching while it runs. Press **Win+Tab** to move to the next desktop. At the last desktop, it wraps to the first. Wrapping passes through intermediate desktops.

### Run

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Run `scripts/DesktopSwitcher.ahk`.

Exit the script from the AutoHotkey icon in the system tray to restore the normal **Win+Tab** Task View shortcut.
