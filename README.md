# AutoHotkey scripts

Small Windows automation scripts written in AutoHotkey v2.

## Desktop switcher

[`ahk/DesktopSwitcher.ahk`](ahk/DesktopSwitcher.ahk) replaces **Win+Tab** with virtual desktop switching while it runs. Press **Win+Tab** to move to the next desktop. At the last desktop, it jumps directly to the first. Press **Win+Shift+Tab** to open Windows Task View.

Requires x64 Windows build **26100.2605 or newer**. Desktop switching uses the bundled [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor) DLL. Windows updates can require a newer DLL.

### Run

1. Install 64-bit [AutoHotkey v2](https://www.autohotkey.com/).
2. Run `ahk/DesktopSwitcher.ahk`, keeping `ahk/lib` beside it.

Exit the script from the AutoHotkey icon in the system tray to restore the normal **Win+Tab** Task View shortcut.

## Build executables

Install AutoHotkey v2 and its [Ahk2Exe script compiler](https://github.com/AutoHotkey/Ahk2Exe). Then run this from the project folder:

```powershell
pwsh -NoProfile -File .\scripts\build.ps1
```

This rebuilds every `.ahk` file in `ahk`, including subfolders, into `bin`. For example, `ahk/DesktopSwitcher.ahk` becomes `bin/DesktopSwitcher.exe`. Run it again after changing a script. Generated executables are ignored by Git.

DesktopSwitcher embeds its DLL in the executable, so no separate DLL is needed in `bin` or Startup. Use a 64-bit AutoHotkey base when compiling it.

After compilation succeeds, the build copies the executables into your Windows Startup folder, which you can open with `shell:startup`. They will run automatically when you sign in. Rebuilding replaces the copies there, so exit any running compiled scripts first. Scripts in different subfolders must have unique filenames.

For a custom installation, provide both paths:

```powershell
.\scripts\build.ps1 -CompilerPath 'C:\AutoHotkey\Compiler\Ahk2Exe.exe' -BasePath 'C:\AutoHotkey\v2\AutoHotkey64.exe'
```
