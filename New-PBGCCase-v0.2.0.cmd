@echo off
setlocal DisableDelayedExpansion
rem PBGC case scaffold launcher v0.2.0. Requires PowerShell 7 (pwsh).
rem Keep New-PBGCCase-v0.2.0.ps1 beside this CMD file.
rem Arguments are the same as the PowerShell script. No policy bypass is used.
where pwsh.exe >nul 2>nul
if errorlevel 1 (
    echo ERROR: PowerShell 7 ^(pwsh.exe^) is required and must be on PATH. 1>&2
    exit /b 1
)
if not exist "%~dp0New-PBGCCase-v0.2.0.ps1" (
    echo ERROR: Place New-PBGCCase-v0.2.0.ps1 beside this CMD file. 1>&2
    exit /b 1
)
pwsh.exe -NoLogo -NoProfile -File "%~dp0New-PBGCCase-v0.2.0.ps1" %*
exit /b %errorlevel%
