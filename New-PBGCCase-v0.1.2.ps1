#requires -Version 7.0
<#
.SYNOPSIS
Creates a PBGC case folder scaffold. Version 0.1.2.
.DESCRIPTION
Creates folders, purpose README files, naming instructions, an empty register,
and Windows navigation shortcuts. Existing content is never overwritten.
The user supplies the case identity; the script does not infer it from files.
Scaffold.json records that identity and the paths at creation time.
This release does not fill templates, rename documents, capture versions,
update register entries, or repair shortcuts automatically.
.PARAMETER TestMode
Uses only TEMP\PBGC-Scaffold-Test-v0.1.2. Defaults to case 00000000-Test-Case.
Optional CaseNumber and ShortName let you test a named case entirely in TEMP.
Do not combine with OneDriveRoot, ActWorkRoot, or ResourcesRoot.
.PARAMETER CaseNumber
Your eight-digit case number, for example 24884900. Supply it for a real case.
Used in folder names and the R1, R5, R0, PF and V1 naming map.
.PARAMETER ShortName
Your short plan name, for example College-of-Saint-Rose. Supply it for a real
case. Used only in the document folder name; it is not part of R1/R5/etc. names.
.PARAMETER OneDriveRoot
Existing parent for case document folders. Defaults to OneDriveCommercial,
or USERPROFILE\OneDrive - PBGC. Supply the exact path if needed.
.PARAMETER ActWorkRoot
Existing parent for software case folders. Defaults to H:\ACTWORK.
.PARAMETER ResourcesRoot
Shared resources folder. Defaults to OneDriveRoot\Actuarial-Resources.
The script creates missing resource folders; no templates are included.
.PARAMETER AdditionalWorkFolder
Optional additional folder names under Work. Re-running can add missing folders.
.EXAMPLE
.\New-PBGCCase-v0.1.2.ps1 -TestMode -WhatIf
Preview the TEMP test without creating anything.
.EXAMPLE
.\New-PBGCCase-v0.1.2.ps1 -TestMode
Create a test scaffold entirely inside TEMP.
.EXAMPLE
.\New-PBGCCase-v0.1.2.ps1 -TestMode -CaseNumber 12345678 -ShortName 'Demo-Plan'
Test your supplied case identity without writing to OneDrive or ACTWORK.
.EXAMPLE
.\New-PBGCCase-v0.1.2.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose' -WhatIf
Preview a real case. Remove WhatIf only after checking the destinations.
.NOTES
Run in PowerShell 7 on Windows, from the directory containing this script.
For full help: Get-Help .\New-PBGCCase-v0.1.2.ps1 -Full
Fresh cases or matching previously scaffolded cases only. Unmanaged nonempty
case folders are refused. Re-runs preserve existing READMEs and Scaffold.json.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$TestMode,
    [ValidatePattern('^[0-9]{8}$')][string]$CaseNumber = '00000000',
    [string]$ShortName = 'Test-Case',
    [string]$OneDriveRoot,
    [string]$ActWorkRoot = 'H:\ACTWORK',
    [string]$ResourcesRoot,
    [string[]]$AdditionalWorkFolder = @()
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ScaffoldVersion = '0.1.2'
$operation = $PSCmdlet
if (-not $IsWindows) { throw 'Run this script in PowerShell 7 on Windows.' }

function Assert-FolderName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -match '[<>:"/\\|?*\x00-\x1f]' -or
        $Name -match '[. ]$' -or $Name -in @('.', '..') -or
        $Name -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') {
        throw "Invalid folder name: $Name"
    }
}
Assert-FolderName $ShortName
foreach ($name in $AdditionalWorkFolder) { Assert-FolderName $name }

if ($TestMode) {
    if ($PSBoundParameters.ContainsKey('OneDriveRoot') -or
        $PSBoundParameters.ContainsKey('ActWorkRoot') -or
        $PSBoundParameters.ContainsKey('ResourcesRoot')) {
        throw 'TestMode uses TEMP only. Do not combine it with destination overrides.'
    }
    $testRoot = Join-Path $env:TEMP 'PBGC-Scaffold-Test-v0.1.2'
    $OneDriveRoot = Join-Path $testRoot 'Documents'
    $ActWorkRoot = Join-Path $testRoot 'ACTWORK'
    $ResourcesRoot = Join-Path $testRoot 'Actuarial-Resources'
} else {
    if ($CaseNumber -eq '00000000' -or -not $PSBoundParameters.ContainsKey('ShortName')) {
        throw 'For a real case, supply -CaseNumber and -ShortName.'
    }
    if (-not $OneDriveRoot) {
        $OneDriveRoot = $env:OneDriveCommercial
        if (-not $OneDriveRoot) { $OneDriveRoot = Join-Path $env:USERPROFILE 'OneDrive - PBGC' }
    }
    if (-not (Test-Path -LiteralPath $OneDriveRoot -PathType Container)) {
        throw 'OneDriveRoot must be an existing directory. Supply its exact path.'
    }
    if (-not (Test-Path -LiteralPath $ActWorkRoot -PathType Container)) {
        throw 'ActWorkRoot must be an existing directory. Supply its exact path.'
    }
    if (-not $ResourcesRoot) { $ResourcesRoot = Join-Path $OneDriveRoot 'Actuarial-Resources' }
}
$OneDriveRoot = [IO.Path]::GetFullPath($OneDriveRoot)
$ActWorkRoot = [IO.Path]::GetFullPath($ActWorkRoot)
$ResourcesRoot = [IO.Path]::GetFullPath($ResourcesRoot)
$casePath = Join-Path $OneDriveRoot "$CaseNumber-$ShortName"
$softwarePath = Join-Path $ActWorkRoot $CaseNumber
$roots = @($casePath, $softwarePath, $ResourcesRoot)
for ($i = 0; $i -lt $roots.Count; $i++) {
    for ($j = $i + 1; $j -lt $roots.Count; $j++) {
        $a = $roots[$i].TrimEnd('\')
        $b = $roots[$j].TrimEnd('\')
        if ($a.Equals($b, [StringComparison]::OrdinalIgnoreCase) -or
            $a.StartsWith($b + '\', [StringComparison]::OrdinalIgnoreCase) -or
            $b.StartsWith($a + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Case, software, and resources roots must be separate, non-nested directories.'
        }
    }
}

# This command is for fresh cases or its own previously scaffolded cases.
foreach ($root in @($casePath, $softwarePath)) {
    $marker = Join-Path $root 'Scaffold.json'
    if (Test-Path -LiteralPath $root) {
        $rootItem = Get-Item -LiteralPath $root
        if (-not $rootItem.PSIsContainer -or $rootItem.LinkType) {
            throw "Destination must be a real directory: $root"
        }
        if (Test-Path -LiteralPath $marker -PathType Leaf) {
            $saved = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
            if ($saved.CaseNumber -ne $CaseNumber -or $saved.DocumentsPath -ne $casePath -or
                $saved.SoftwarePath -ne $softwarePath -or $saved.ResourcesPath -ne $ResourcesRoot) {
                throw "Existing scaffold configuration differs: $marker"
            }
        } elseif (@(Get-ChildItem -LiteralPath $root -Force).Count -gt 0) {
            throw "Existing nonempty case has no scaffold marker. No changes made: $root"
        }
    }
}

$folders = [ordered]@{}
$folders[$casePath] = "Case $CaseNumber - $ShortName. Identity supplied through -CaseNumber and -ShortName and recorded in Scaffold.json. See Usage-v0.1.2.txt for commands and File-Naming.txt for required filenames." + ' Case navigation and register. Keep original sources in Sources and current work in Work. Use shortcuts to access a file elsewhere; do not create extra working copies.'
$folders[(Join-Path $casePath 'Sources')] = 'Unaltered received records: plan documents, amendments, valuations, AFTAP certifications, census deliveries, Form 5500s, and Image Viewer records. Store each source once.'
$folders[(Join-Path $casePath 'Work')] = 'Current case-specific work. Each document has one authoritative location. Add subfolders only when needed.'
$folders[(Join-Path $casePath 'Work\Upfront')] = 'Completed R5 files use the case number immediately followed by R5, with the original extension. Current AMB acceptance, R5/Plan Summary, DEL, section 436 evaluation, estimated benefit adjustment and administration documents. Shared blank masters remain in Templates.'
$folders[(Join-Path $casePath 'Work\Data')] = 'Working database exports, prepared inputs, reconciliation and correction records. Unaltered deliveries remain in Sources.'
$folders[(Join-Path $casePath 'Work\BET')] = 'Benefit estimate calculators, testing, participant calculations, and outputs. Distinct participant scenarios are separate work products, not automatically earlier versions.'
$folders[(Join-Path $casePath 'Work\Actuarial')] = 'Completed R1 files use the case number immediately followed by R1, with the original extension. Current supporting calculations, PTPL/QDRO work as applicable, factors, listings, validation reports, statements, R1/Case Memo, and CMS reports. Active V1/PF files remain on ACTWORK.'
$folders[(Join-Path $casePath 'Reviews')] = 'Create a folder per review when needed. Use shortcuts to the exact preserved versions reviewed; keep comments, responses, and submission evidence here. Do not send shortcuts to recipients who cannot access their targets.'
$folders[(Join-Path $casePath 'Closeout')] = 'The package index is R0: name it with the case number immediately followed by R0, with the original extension. Store the authoritative index here. Shortcuts to approved versions and closeout evidence, including confirmation. Approved files have one authoritative location. External submissions require real files, not local shortcuts.'
$folders[(Join-Path $casePath 'History')] = 'Preserved previous document versions, stored once. Never edit a version referenced by a completed review. This scaffold does not automatically capture versions or repair file links.'
$folders[$softwarePath] = 'Active V1 and PF filenames start with the case number immediately followed by V1 or PF, with their original extensions; no spaces or separators. Active V1, PF, and other software-required files belong at their required paths. This script does not create empty workbooks or configuration files.'
$folders[(Join-Path $softwarePath 'BSRS')] = 'BSRS files at application-required locations. Confirm the BR, BS, and BSR_TEST layout for the case before use.'
foreach ($sub in @('BR', 'BS', 'BSR_TEST')) {
    $folders[(Join-Path $softwarePath "BSRS\$sub")] = "BSRS $sub files at their required application paths. Retain required filenames and internal relationships."
}
$folders[(Join-Path $softwarePath 'History')] = 'Previous software versions preserved once. Maintain matching V1/PF/configuration sets when needed. Version capture is not performed by this scaffold.'
$folders[$ResourcesRoot] = 'Resources shared by all cases. Maintain master templates and reference material here instead of copying them into every case.'
$folders[(Join-Path $ResourcesRoot 'Templates')] = 'Shared blank master templates, with original filenames retained. Create a distinct case-specific document only when needed. After entering the case information, name the completed R1/R5/R0/PF/V1 file using the case naming map. Never rename or edit the shared master. This script does not copy or modify templates.'
$folders[(Join-Path $ResourcesRoot 'Reference')] = 'Reusable guidance, sample language, examples, and supporting documentation shared across cases.'
$folders[(Join-Path $ResourcesRoot 'PowerShell')] = 'Permanent master scripts. Run a temporary execution copy from TEMP as needed. Do not store case data here.'
foreach ($name in $AdditionalWorkFolder) {
    $path = Join-Path (Join-Path $casePath 'Work') $name
    if (-not $folders.Contains($path)) { $folders[$path] = "Additional case work: $name. Keep authoritative files here; use shortcuts elsewhere. Update this README to describe its purpose." }
}

# Required software closeout stems. Preserve the actual source file extension.
# Each editable document and its issued PDF are different formats of one work product.
$caseFilenames = [ordered]@{
    SchemaVersion = '1.0'
    ScaffoldVersion = $ScaffoldVersion
    CaseNumber = $CaseNumber
    Files = @(
        [ordered]@{ Code = 'R1'; FileStem = "${CaseNumber}R1"; Folder = (Join-Path $casePath 'Work\Actuarial') }
        [ordered]@{ Code = 'R5'; FileStem = "${CaseNumber}R5"; Folder = (Join-Path $casePath 'Work\Upfront') }
        [ordered]@{ Code = 'R0'; FileStem = "${CaseNumber}R0"; Folder = (Join-Path $casePath 'Closeout') }
        [ordered]@{ Code = 'PF'; FileStem = "${CaseNumber}PF"; Folder = $softwarePath }
        [ordered]@{ Code = 'V1'; FileStem = "${CaseNumber}V1"; Folder = $softwarePath }
    )
}
$namingGuide = @"
Case file naming - scaffold v$ScaffoldVersion

Keep the shared blank templates unchanged, under their original names.
When case information is complete, name the case file with its required stem:

${CaseNumber}R1 - actuarial case report/memo - Work\Actuarial
${CaseNumber}R5 - plan summary - Work\Upfront
${CaseNumber}R0 - package index - Closeout
${CaseNumber}PF - PF workbook - ACTWORK case root
${CaseNumber}V1 - V1 workbook - ACTWORK case root

The case number immediately precedes the code. No spaces, hyphens or underscores.
Preserve the real file extension. Renaming does not convert a file format.
For example: ${CaseNumber}R1.docx, ${CaseNumber}R1.pdf, ${CaseNumber}PF.xlsx.
Do not append draft/final labels, dates or version suffixes to these current names.
Keep superseded versions in History, with distinct version identification there.
Use shortcuts elsewhere in the case, including review and closeout folders.
Before replacing a file used in a completed review, preserve that exact version
and ensure the review shortcut points to that preserved version.
This scaffold records the naming rules; it does not rename existing files,
instantiate templates, capture versions, or repair shortcuts automatically.
Case-Filenames.json contains the required stems and authoritative folders.
"@

$usageGuide = @"
PBGC case scaffold v$ScaffoldVersion

CASE IDENTITY
Case number: $CaseNumber
Short plan name: $ShortName
Documents: $casePath
Software: $softwarePath
Shared resources: $ResourcesRoot

You supply the identity through -CaseNumber and -ShortName. Nothing is guessed.
Scaffold.json records it at creation. Case-Filenames.json lists required names.
The short name is used in the document folder, not the R1/R5/R0/PF/V1 filenames.

COMMANDS (from the folder containing the script)
Preview a TEMP test:
.\New-PBGCCase-v0.1.2.ps1 -TestMode -WhatIf
Create a TEMP test:
.\New-PBGCCase-v0.1.2.ps1 -TestMode
Preview a real case (replace both example values with your case):
.\New-PBGCCase-v0.1.2.ps1 -CaseNumber 12345678 -ShortName 'Demo-Plan' -WhatIf
After checking the paths, remove -WhatIf to create the real case.
Full parameter help:
Get-Help .\New-PBGCCase-v0.1.2.ps1 -Full

RERUNS AND LIMITS
Use the same identity and destination parameters when re-running a real case.
Existing files, READMEs, configuration and shortcuts are preserved.
-AdditionalWorkFolder 'New-Workstream' adds a missing Work subfolder.
This command does not reorganize an existing tree or delete folders.
Shared blank templates retain their original names. Create case documents from
those masters as needed; use File-Naming.txt when saving completed documents.
Automatic renaming, version capture, register updates and shortcut repair are
not implemented. Set-PBGCCaseFile is a proposed command, not available here.
"@

$links = [ordered]@{
    (Join-Path $casePath 'ACTWORK.lnk') = $softwarePath
    (Join-Path $casePath 'Templates.lnk') = (Join-Path $ResourcesRoot 'Templates')
    (Join-Path $softwarePath 'Case-Documents.lnk') = $casePath
}
# Preflight all planned locations before creating anything.
foreach ($path in $folders.Keys) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path
        if (-not $item.PSIsContainer -or $item.LinkType) { throw "Expected a real folder: $path" }
    }
    $readme = Join-Path $path 'README.txt'
    if ((Test-Path -LiteralPath $readme) -and -not (Test-Path -LiteralPath $readme -PathType Leaf)) {
        throw "Expected a README file: $readme"
    }
}
$shell = New-Object -ComObject WScript.Shell
foreach ($path in $links.Keys) {
    if (Test-Path -LiteralPath $path) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Shortcut path is not a file: $path" }
        $existingLink = $shell.CreateShortcut($path)
        if ($existingLink.TargetPath -ne $links[$path]) { throw "Existing shortcut has a different target: $path" }
    }
}

function Write-NewText([string]$Path, [string]$Text) {
    if (Test-Path -LiteralPath $Path) { return }
    if ($operation.ShouldProcess($Path, 'Create file without overwriting')) {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
            $stream.Write($bytes, 0, $bytes.Length)
        } finally { $stream.Dispose() }
    }
}
try {
    $index = 0
    foreach ($path in $folders.Keys) {
        $index++
        Write-Progress -Activity 'Create PBGC case scaffold' -Status $path -PercentComplete (100 * $index / $folders.Count)
        if (-not (Test-Path -LiteralPath $path)) {
            if ($operation.ShouldProcess($path, 'Create directory')) { [IO.Directory]::CreateDirectory($path) | Out-Null }
        }
        Write-NewText (Join-Path $path 'README.txt') ($folders[$path] + "`r`n")
    }
    $config = [ordered]@{
        ScaffoldVersion = $ScaffoldVersion; CaseNumber = $CaseNumber; ShortName = $ShortName
        DocumentsPath = $casePath; SoftwarePath = $softwarePath; ResourcesPath = $ResourcesRoot
        CreatedUtc = [DateTime]::UtcNow.ToString('o'); TestMode = [bool]$TestMode
    } | ConvertTo-Json
    foreach ($root in @($casePath, $softwarePath)) { Write-NewText (Join-Path $root 'Scaffold.json') $config }
    Write-NewText (Join-Path $casePath 'Case-Filenames.json') ($caseFilenames | ConvertTo-Json -Depth 5)
    Write-NewText (Join-Path $casePath 'Usage-v0.1.2.txt') ($usageGuide + "`r`n")
    Write-NewText (Join-Path $casePath 'File-Naming.txt') ($namingGuide + "`r`n")
    Write-NewText (Join-Path $casePath 'Case-Register.csv') ('"FileId","Purpose","AuthoritativePath","Version","Status"' + "`r`n")
    foreach ($path in $links.Keys) {
        if (-not (Test-Path -LiteralPath $path)) {
            if ($operation.ShouldProcess($path, "Create navigation shortcut to $($links[$path])")) {
                $shortcut = $shell.CreateShortcut($path)
                $shortcut.TargetPath = $links[$path]
                $shortcut.Save()
            }
        }
    }
} finally { Write-Progress -Activity 'Create PBGC case scaffold' -Completed }
[pscustomobject]@{
    Version = $ScaffoldVersion; Preview = [bool]$WhatIfPreference
    Documents = $casePath; Software = $softwarePath; Resources = $ResourcesRoot
}
