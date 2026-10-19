#Requires -Version 5.1
<#
.SYNOPSIS
Rebuilds every .ahk script under ahk into the bin directory.
.PARAMETER CompilerPath
Path to Ahk2Exe.exe, if it is not installed in a standard location.
.PARAMETER BasePath
Path to an AutoHotkey v2 executable, if it cannot be found automatically.
#>
[CmdletBinding()]
param(
    [string]$CompilerPath,
    [string]$BasePath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $projectRoot 'ahk'
$outputRoot = Join-Path $projectRoot 'bin'

$installRoots = @(
    "$env:ProgramFiles\AutoHotkey"
    "${env:ProgramFiles(x86)}\AutoHotkey"
    "$env:LOCALAPPDATA\Programs\AutoHotkey"
    "$env:LOCALAPPDATA\AutoHotkey"
)
foreach ($registryPath in @('HKCU:\SOFTWARE\AutoHotkey', 'HKLM:\SOFTWARE\AutoHotkey')) {
    $installation = Get-ItemProperty -LiteralPath $registryPath -ErrorAction SilentlyContinue
    if ($installation.InstallDir) {
        $installRoots += $installation.InstallDir
    }
}

if (!$CompilerPath) {
    $compilerCommand = Get-Command Ahk2Exe.exe -CommandType Application -ErrorAction SilentlyContinue
    $compilerCandidates = @(
        if ($compilerCommand) { $compilerCommand.Source }
        foreach ($installRoot in $installRoots) {
            Join-Path $installRoot 'Compiler\Ahk2Exe.exe'
        }
    )
    $CompilerPath = $compilerCandidates | Where-Object {
        Test-Path -LiteralPath $_ -PathType Leaf
    } | Select-Object -First 1
}
if (!$CompilerPath -or !(Test-Path -LiteralPath $CompilerPath -PathType Leaf)) {
    throw 'Ahk2Exe.exe was not found. Install the AutoHotkey script compiler or pass -CompilerPath "C:\path\Ahk2Exe.exe".'
}
$CompilerPath = (Resolve-Path -LiteralPath $CompilerPath).Path
$compilerDirectory = Split-Path -Parent $CompilerPath
$installRoots += $compilerDirectory
$installRoots += Split-Path -Parent $compilerDirectory

if (!$BasePath) {
    $baseCandidates = @(
        foreach ($installRoot in ($installRoots | Select-Object -Unique)) {
            foreach ($relativePath in @('v2\AutoHotkey64.exe', 'AutoHotkey64.exe', 'v2\AutoHotkey32.exe', 'AutoHotkey32.exe')) {
                Join-Path $installRoot $relativePath
            }
        }
    )
    $BasePath = $baseCandidates | Where-Object {
        (Test-Path -LiteralPath $_ -PathType Leaf) -and
        (Get-Item -LiteralPath $_).VersionInfo.FileMajorPart -eq 2
    } | Select-Object -First 1
}
if (!$BasePath -or !(Test-Path -LiteralPath $BasePath -PathType Leaf)) {
    throw 'AutoHotkey v2 was not found. Install AutoHotkey v2 or pass -BasePath "C:\path\AutoHotkey64.exe".'
}
$BasePath = (Resolve-Path -LiteralPath $BasePath).Path
if ((Get-Item -LiteralPath $BasePath).VersionInfo.FileMajorPart -ne 2) {
    throw '-BasePath must point to an AutoHotkey v2 executable.'
}

$scripts = @(Get-ChildItem -LiteralPath $sourceRoot -Filter '*.ahk' -File -Recurse | Sort-Object FullName)
if ($scripts.Count -eq 0) {
    throw "No AutoHotkey scripts were found in $sourceRoot."
}

foreach ($script in $scripts) {
    $relativePath = $script.FullName.Substring($sourceRoot.Length + 1)
    $outputPath = Join-Path $outputRoot ([IO.Path]::ChangeExtension($relativePath, '.exe'))
    New-Item -ItemType Directory -Path (Split-Path -Parent $outputPath) -Force | Out-Null

    Write-Host "Compiling $relativePath"
    # Start-Process needs explicit quotes around paths containing spaces.
    $compilerArguments = @(
        '/in', ('"{0}"' -f $script.FullName)
        '/out', ('"{0}"' -f $outputPath)
        '/base', ('"{0}"' -f $BasePath)
        '/compress', '0'
        '/silent', 'verbose'
    )
    $compiler = Start-Process -FilePath $CompilerPath -ArgumentList $compilerArguments `
        -WorkingDirectory $script.DirectoryName -NoNewWindow -Wait -PassThru
    if ($compiler.ExitCode -ne 0) {
        throw "Compilation failed for $relativePath with exit code $($compiler.ExitCode)."
    }
    if (!(Test-Path -LiteralPath $outputPath -PathType Leaf)) {
        throw "The compiler did not create $outputPath."
    }
}

Write-Host "Compiled $($scripts.Count) script(s) into $outputRoot"
