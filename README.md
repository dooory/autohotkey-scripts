# AutoHotkey scripts

Small Windows automation scripts written in AutoHotkey v2.

## Desktop switcher

[`ahk/DesktopSwitcher.ahk`](ahk/DesktopSwitcher.ahk) replaces **Win+Tab** with virtual desktop switching while it runs. Press **Win+Tab** to move to the next desktop. At the last desktop, it wraps to the first. Wrapping passes through intermediate desktops. Press **Win+Shift+Tab** to open Windows Task View.

### Run

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Run `ahk/DesktopSwitcher.ahk`.

Exit the script from the AutoHotkey icon in the system tray to restore the normal **Win+Tab** Task View shortcut.

## Build executables

Install AutoHotkey v2 and its [Ahk2Exe script compiler](https://github.com/AutoHotkey/Ahk2Exe). Then run this from the project folder:

```powershell
pwsh -NoProfile -File .\scripts\build.ps1
```

This rebuilds every `.ahk` file in `ahk`, including subfolders, into `bin`. For example, `ahk/DesktopSwitcher.ahk` becomes `bin/DesktopSwitcher.exe`. Run it again after changing a script. Generated executables are ignored by Git.

For a custom installation, provide both paths:

```powershell
.\scripts\build.ps1 -CompilerPath 'C:\AutoHotkey\Compiler\Ahk2Exe.exe' -BasePath 'C:\AutoHotkey\v2\AutoHotkey64.exe'
```
