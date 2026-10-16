# PBGC case scaffolding

[![Version 0.2.1](https://img.shields.io/badge/version-0.2.1-blue)](CHANGELOG.md)
[![Linux tests: 17 passing](https://img.shields.io/badge/Linux_tests-17_passing-brightgreen)](#version-history-and-validation)
[![Template SHA-256: 8 verified](https://img.shields.io/badge/template_SHA--256-8_verified-brightgreen)](Actuarial-Resources/Templates/catalog.json)
[![Windows validation: pending](https://img.shields.io/badge/Windows_validation-pending-yellow)](#version-history-and-validation)

Status snapshots checked on **2026-10-16**. Test and integrity badges reflect locally verified results, not a live CI feed or external certification. Latest-version Windows testing remains pending.

Current version: **0.2.1**. Choose the entry point for your terminal:

| Terminal | Download | Requirement |
|---|---|---|
| PowerShell on Windows | [New-PBGCCase-v0.2.1.ps1](New-PBGCCase-v0.2.1.ps1) | PowerShell 7 |
| CMD on Windows | [New-PBGCCase-v0.2.1.cmd](New-PBGCCase-v0.2.1.cmd) **and the matching PS1 above**, in the same folder | PowerShell 7 (`pwsh.exe`) on PATH |
| Bash on Linux, macOS or WSL | [new-pbgc-case-v0.2.1.sh](new-pbgc-case-v0.2.1.sh) | Bash and Python 3.8+ (`python3`) |

Creates a fresh case tree, folder instructions, a filename map, an empty case register, and navigation shortcuts. Eight original attachments, including templates, checklist and sample language, are bundled in [Actuarial-Resources/Templates](Actuarial-Resources/Templates). A normal clone includes the actual files. The catalog records sizes and SHA-256 hashes.

For a real case, scripts 0.2.1 detect `Actuarial-Resources` beside the script when its template catalog exists. Case links point to that one collection. If executing a script copied to TEMP, pass the clone's resources folder explicitly: `-ResourcesRoot 'C:\YourClone\Actuarial-Resources'` for PowerShell/CMD or `--resources-root '/your/clone/Actuarial-Resources'` for Bash. Explicit paths override detection. Without a bundle or override, the previous document-parent default applies. Keep the clone at a stable path so links remain valid.

Test mode stays isolated in TEMP and does not copy the masters. One received checklist was already completed and digitally signed; it is excluded from the public collection pending direction. The template catalog records this exclusion and missing masters.

## CMD quick start

Download both the CMD and PS1 files and keep them together. From CMD in that folder:

```bat
New-PBGCCase-v0.2.1.cmd -TestMode -WhatIf
New-PBGCCase-v0.2.1.cmd -TestMode
```

The CMD file launches the exact same PowerShell implementation and forwards its arguments and exit code. It is not a second independent implementation. It does not bypass execution policy or signing requirements. If the PS1 is blocked, review it and follow your office's approved process; the file-specific PowerShell unblocking command is below. All Windows parameter, path and filename instructions below apply to CMD too. Full help from CMD:

```bat
pwsh.exe -NoProfile -Command "Get-Help '.\New-PBGCCase-v0.2.1.ps1' -Full"
```

If you downloaded the whole repository, an optional Windows smoke test is included. From PowerShell, run `./tests/Test-WindowsScaffold-v0.2.1.ps1` after any required approval/unblocking. It checks CMD preview, naming, shortcut targets and a rerun, using a unique TEMP sandbox retained for inspection. It does not touch real cases.

## Bash quick start

Download the SH file; it is standalone (its Python implementation is embedded). No packages or network connection are needed at runtime. Run it explicitly with Bash, so no executable-bit change is required:

```bash
bash ./new-pbgc-case-v0.2.1.sh --test-mode --what-if
bash ./new-pbgc-case-v0.2.1.sh --test-mode
bash ./new-pbgc-case-v0.2.1.sh --help
```

The test tree is `PBGC-Scaffold-Test-v0.2.1` under the OS temporary directory, selected by Python's standard temporary-directory rules (`TMPDIR`, `TEMP`, `TMP`, then the OS default). The JSON output reports exact destinations. It need not be Windows `%TEMP%` or `/tmp` on every machine.

Real cases require explicit **existing POSIX parent paths**. Replace the example paths and identity; preview first:

```bash
bash ./new-pbgc-case-v0.2.1.sh --case-number 12345678 --short-name 'Demo-Plan' --documents-root '/your/existing/documents-parent' --actwork-root '/your/existing/software-parent' --what-if
```

Remove `--what-if` only after checking the paths. Optional `--resources-root` selects the shared resources folder; otherwise the adjacent bundle is used when its catalog exists, falling back to `Actuarial-Resources` under the document parent. Repeat `--additional-work-folder 'Name'` to add work folders. `--test-mode` also accepts `--case-number` and `--short-name` but not destination overrides. PowerShell-style aliases such as `-TestMode` and `-CaseNumber` are accepted too.

Bash creates directory **symbolic links**, named `ACTWORK`, `Templates` and `Case-Documents`, not Windows `.lnk` files. It uses the same case identities, required filename stems and logical folder layout. The `PowerShell` resources folder is retained for compatibility and may also hold shell launchers. Windows software filenames and application paths are not changed by creating a Linux tree. Use the CMD/PowerShell version for your actual Windows office case folders. Git Bash on Windows should use the CMD/PowerShell entry point, not the POSIX generator. WSL needs explicitly mounted POSIX paths; do not assume `H:` is mounted there.

## Windows PowerShell instructions

## 1. Download and prepare

Download [New-PBGCCase-v0.2.1.ps1](New-PBGCCase-v0.2.1.ps1) using GitHub's **Download raw file** button. Save it in your permitted script directory, for example your existing `testing-scaff` folder in TEMP. Open PowerShell there. Commands below assume the script is in your current directory; running it there does not restrict where its destination folders are created.

If this newly downloaded file is blocked as unsigned, review it first. If your office permits unblocking it, run:

```powershell
Unblock-File -LiteralPath '.\New-PBGCCase-v0.2.1.ps1'
```

Unblocking is once per downloaded file, not every execution. A newly downloaded version may need unblocking again. This does not change your execution policy. If organizational policy requires a signed script, use your approved signing process.

## 2. Final test — TEMP only

Preview without writes:

```powershell
.\New-PBGCCase-v0.2.1.ps1 -TestMode -WhatIf
```

Create the test:

```powershell
.\New-PBGCCase-v0.2.1.ps1 -TestMode
```

Open its folders:

```powershell
explorer.exe (Join-Path $env:TEMP 'PBGC-Scaffold-Test-v0.2.1')
```

`Documents`, `ACTWORK` and `Actuarial-Resources` are all created under this TEMP test root. Without identity parameters, the test case is `00000000-Test-Case`. No actual OneDrive or H: case is created in TestMode. Do not combine TestMode with destination overrides.

To test supplied identity values, still entirely in TEMP:

```powershell
.\New-PBGCCase-v0.2.1.ps1 -TestMode -CaseNumber 12345678 -ShortName 'Demo-Plan'
```

Check that purpose READMEs, `Scaffold.json`, `Case-Filenames.json`, `File-Naming.txt`, and `Usage-v0.2.1.txt` exist. Open the navigation shortcuts and confirm their targets. Re-run the same test; existing files should remain unchanged.

## 3. Create a real case

**You supply the case number and short plan name. The script does not discover or guess them.** Replace the example values with the new case's actual values.

First preview:

```powershell
.\New-PBGCCase-v0.2.1.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose' -WhatIf
```

After checking destinations, remove `-WhatIf`:

```powershell
.\New-PBGCCase-v0.2.1.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose'
```

These examples are for a **fresh case**, not migration of an existing populated case. An unmanaged nonempty case folder is refused.

| Parameter | Meaning / default |
|---|---|
| `-CaseNumber` | Your eight-digit case number. Required for a real case; used in folder names and required file stems. |
| `-ShortName` | Your short plan name. Required for a real case; used only in the document folder name. |
| `-OneDriveRoot` | Existing document parent. Defaults to `$env:OneDriveCommercial`, otherwise `$env:USERPROFILE\OneDrive - PBGC`. |
| `-ActWorkRoot` | Existing software parent. Defaults to `H:\ACTWORK`. |
| `-ResourcesRoot` | Explicit shared resources folder; otherwise uses the adjacent bundled folder when its catalog exists, then the document-parent default. TestMode always uses TEMP. |
| `-AdditionalWorkFolder` | Optional additional folder names under `Work`. |
| `-TestMode` | Uses a separate TEMP tree for this script version. |
| `-WhatIf` | Reports proposed writes without creating files, folders or shortcuts. |

If your actual parent paths differ, supply them explicitly:

```powershell
.\New-PBGCCase-v0.2.1.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose' -OneDriveRoot 'C:\Users\bekog82\OneDrive - PBGC' -ActWorkRoot 'H:\ACTWORK' -ResourcesRoot 'C:\Users\bekog82\OneDrive - PBGC\Actuarial-Resources' -WhatIf
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
.\New-PBGCCase-v0.2.1.ps1 -CaseNumber 24884900 -ShortName 'College-of-Saint-Rose' -AdditionalWorkFolder 'Special-Calculations' -WhatIf
```

Supply the same destination overrides too, if you originally used them. Remove WhatIf after reviewing the preview. Existing README files are not rewritten; `Usage-v0.2.1.txt` is a new versioned guide added to the document root.

Full script help:

```powershell
Get-Help .\New-PBGCCase-v0.2.1.ps1 -Full
```

## Version history and validation

Prior versioned scripts remain unchanged. See [CHANGELOG.md](CHANGELOG.md). Run `python3 -m unittest discover -s tests -v` from the repository root: all 17 tests passed on Linux, including bundle integrity, automatic resource selection, isolated previews and preservation on rerun. PowerShell 0.2.1 adds resource detection to the previously tested engine; actual Windows CMD/COM execution of this version remains pending. This is a personal work-organization tool, not a statement of official PBGC procedures.
