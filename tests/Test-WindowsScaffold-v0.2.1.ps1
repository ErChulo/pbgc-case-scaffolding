#requires -Version 7.0
# Optional office smoke test. Creates a unique TEMP sandbox and retains it for inspection.
# Run from PowerShell: .\tests\Test-WindowsScaffold-v0.2.1.ps1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'Windows is required for the CMD and .lnk smoke test.' }
$launcher = Join-Path (Split-Path $PSScriptRoot -Parent) 'New-PBGCCase-v0.2.1.cmd'
$originalTemp = $env:TEMP
$sandbox = Join-Path $env:TEMP ('PBGC-CMD-Check-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($sandbox) | Out-Null
try {
    $env:TEMP = $sandbox
    $testRoot = Join-Path $sandbox 'PBGC-Scaffold-Test-v0.2.1'
    & $launcher -TestMode -WhatIf
    if ($LASTEXITCODE -ne 0 -or (Test-Path -LiteralPath $testRoot)) {
        throw 'CMD preview failed or created the scaffold.'
    }
    & $launcher -TestMode -CaseNumber 12345678 -ShortName 'Demo-Plan'
    if ($LASTEXITCODE -ne 0) { throw 'CMD scaffold creation failed.' }
    $documents = Join-Path $testRoot 'Documents\12345678-Demo-Plan'
    $software = Join-Path $testRoot 'ACTWORK\12345678'
    $map = Get-Content -LiteralPath (Join-Path $documents 'Case-Filenames.json') -Raw | ConvertFrom-Json
    if (($map.Files.FileStem -join ',') -ne '12345678R1,12345678R5,12345678R0,12345678PF,12345678V1') {
        throw 'Unexpected naming map.'
    }
    $shell = New-Object -ComObject WScript.Shell
    $target = $shell.CreateShortcut((Join-Path $documents 'ACTWORK.lnk')).TargetPath
    if ($target -ne $software) { throw 'ACTWORK shortcut target is wrong.' }
    $readme = Join-Path $documents 'README.txt'
    $before = (Get-FileHash -LiteralPath $readme -Algorithm SHA256).Hash
    & $launcher -TestMode -CaseNumber 12345678 -ShortName 'Demo-Plan'
    if ($LASTEXITCODE -ne 0 -or (Get-FileHash -LiteralPath $readme -Algorithm SHA256).Hash -ne $before) {
        throw 'CMD rerun failed or changed the README.'
    }
    Write-Output "PASS: CMD preview, identity, naming, shortcut and rerun. Inspect $sandbox"
} finally {
    $env:TEMP = $originalTemp
}
