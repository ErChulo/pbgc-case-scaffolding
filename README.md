# PBGC case scaffolding

Current version: **0.1.2**. Requires **Windows and PowerShell 7**.

Creates a fresh case tree, folder instructions, a filename map, an empty case register, and navigation shortcuts. Shared resources are created as folders; templates and reference files are not included.

## 1. Download and prepare

Download [New-PBGCCase-v0.1.2.ps1](New-PBGCCase-v0.1.2.ps1) using GitHub's **Download raw file** button. Save it in your permitted script directory, for example your existing `testing-scaff` folder in TEMP. Open PowerShell there. Commands below assume the script is in your current directory; running it there does not restrict where its destination folders are created.

If this newly downloaded file is blocked as unsigned, review it first. If your office permits unblocking it, run:

```powershell
Unblock-File -LiteralPath '.\New-PBGCCase-v0.1.2.ps1'
```

Unblocking is once per downloaded file, not every execution. A newly downloaded version may need unblocking again. This does not change your execution policy. If organizational policy requires a signed script, use your approved signing process.

## 2. Final test — TEMP only

Preview without writes:

```powershell
.\New-PBGCCase-v0.1.2.ps1 -TestMode -WhatIf
```

Create the test:

```powershell
.\New-PBGCCase-v0.1.2.ps1 -TestMode
```

Open its folders:

```powershell
explorer.exe (Join-Path $env:TEMP 'PBGC-Scaffold-Test-v0.1.2')
```

`Documents`, `ACTWORK` and `Actuarial-Resources` are all created under this TEMP test root. Without identity parameters, the test case is `00000000-Test-Case`. No actual OneDrive or H: case is created in TestMode. Do not combine TestMode with destination overrides.

To test supplied identity values, still entirely in TEMP:

```powershell
.\New-PBGCCase-v0.1.2.ps1 -TestMode -CaseNumber 12345678 -ShortName 'Demo-Plan'
```

Check that purpose READMEs, `Scaffold.json`, `Case-Filenames.json`, `File-Naming.txt`, and `Usage-v0.1.2.txt` exist. Open the navigation shortcuts and confirm their targets. Re-run the same test; existing files should remain unchanged.

## 3. Create a real case

**You supply the case number and short plan name. The script does not discover or guess them.** Replace the example values with the new case's actual values.

First preview:

```powershell
.\New-PBGCCase-v0.1.2.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose' -WhatIf
```

After checking destinations, remove `-WhatIf`:

```powershell
.\New-PBGCCase-v0.1.2.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose'
```

These examples are for a **fresh case**, not migration of an existing populated case. An unmanaged nonempty case folder is refused.

| Parameter | Meaning / default |
|---|---|
| `-CaseNumber` | Your eight-digit case number. Required for a real case; used in folder names and required file stems. |
| `-ShortName` | Your short plan name. Required for a real case; used only in the document folder name. |
| `-OneDriveRoot` | Existing document parent. Defaults to `$env:OneDriveCommercial`, otherwise `$env:USERPROFILE\OneDrive - PBGC`. |
| `-ActWorkRoot` | Existing software parent. Defaults to `H:\ACTWORK`. |
| `-ResourcesRoot` | Shared resources location. Defaults to `Actuarial-Resources` under OneDriveRoot; missing resource folders are created. |
| `-AdditionalWorkFolder` | Optional additional folder names under `Work`. |
| `-TestMode` | Uses a separate TEMP tree for this script version. |
| `-WhatIf` | Reports proposed writes without creating files, folders or shortcuts. |

If your actual parent paths differ, supply them explicitly:

```powershell
.\New-PBGCCase-v0.1.2.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose' -OneDriveRoot 'C:\Users\bekog82\OneDrive - PBGC' -ActWorkRoot 'H:\ACTWORK' -ResourcesRoot 'C:\Users\bekog82\OneDrive - PBGC\Actuarial-Resources' -WhatIf
```

The example identity creates the document folder `24884900-College-of-Saint-Rose` and software folder `H:\ACTWORK\24884900`. `Scaffold.json` records the supplied identity and resolved paths at creation time.

## 4. Completed case filenames

Keep shared blank masters under their original names in `Actuarial-Resources\Templates`. Create a case-specific document when needed. Once the case information is entered, save the completed file with the required stem plus its actual extension:

| Type | Example stem | Authoritative location |
|---|---|---|
| R1 — case report/memo | `24884900R1` | `Work\Actuarial` |
| R5 — plan summary | `24884900R5` | `Work\Upfront` |
| R0 — package index | `24884900R0` | `Closeout` |
| PF | `24884900PF` | ACTWORK case root |
| V1 | `24884900V1` | ACTWORK case root |

The number immediately precedes the code. The short plan name is not included. For example: `24884900R1.docx`, `24884900R1.pdf`, `24884900PF.xlsx`. Preserve the actual extension; renaming does not convert a file format. Keep current software-required names free of date/version suffixes. Preserve superseded versions once in History and use shortcuts elsewhere.

**This release records these rules; it does not automatically rename or move case files.** `Set-PBGCCaseFile` is a proposed future command and is not included. No template filling, historical version capture, register maintenance, or automatic shortcut repair is implemented.

## 5. Re-running and adapting

Use the same identity and destination parameters to re-run a real scaffold. Missing items are added; existing files, READMEs, identity markers and shortcuts are preserved. A changed saved path configuration or conflicting shortcut causes an error. The script does not migrate folders or delete anything.

To add a work folder, use the original case parameters plus:

```powershell
.\New-PBGCCase-v0.1.2.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose' -AdditionalWorkFolder 'Special-Calculations' -WhatIf
```

Supply the same destination overrides too, if you originally used them. Remove WhatIf after reviewing the preview. Existing README files are not rewritten; `Usage-v0.1.2.txt` is a new versioned guide added to the document root.

Full script help:

```powershell
Get-Help .\New-PBGCCase-v0.1.2.ps1 -Full
```

## Version history and validation

Prior versioned scripts remain unchanged. See [CHANGELOG.md](CHANGELOG.md). Syntax and documentation consistency were checked for 0.1.2; its actual Windows/COM execution remains to be tested. Version 0.1.0 previously ran on the user's Windows machine. This is a personal work-organization tool, not a statement of official PBGC procedures.
