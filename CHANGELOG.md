# Changelog

## 0.2.0 — 2026-10-16

- Add a CMD launcher forwarding parameters and exit status to the matching PowerShell 7 script. Both files must be downloaded together. No execution-policy bypass is used.
- Add a standalone Bash launcher for Linux/macOS/WSL, with an embedded Python 3.8+ implementation. Uses explicit POSIX paths for real cases, directory symlinks instead of Windows shortcuts, and no network access at runtime.
- Preserve the case tree, identity/configuration fields, five required filename stems, per-folder instructions, empty register, preview and no-overwrite behavior across entry points.
- Add 14 automated Bash behavioral/safety tests and an optional Windows CMD/shortcut smoke test. Add line-ending rules and a VERSION file.
- Keep PowerShell 0.1.0–0.1.2 files unchanged. PowerShell 0.2.0 is byte-for-byte 0.1.2 with version identifiers changed; its test tree is version-specific.
- Validation: Bash syntax check and all 14 behavioral tests pass on Linux. Actual macOS/WSL and Windows CMD smoke tests have not been run in this environment. The user previously confirmed PowerShell 0.1.2 works at the office.
- No automatic renaming, template filling, register updates, run capture or link repair is added.

## 0.1.2 — 2026-10-16

- Add full PowerShell comment-based help for all parameters and examples for TEMP tests, supplied identity, and real-case previews.
- Replace the placeholder README with download, unblocking, test, case-creation, path-override, filename, rerun, and limitation instructions.
- Add case identity and help pointers to newly generated document-root README files, plus a versioned `Usage-v0.1.2.txt` guide that can be added without overwriting earlier instructions.
- Preserve version 0.1.0 and 0.1.1 scripts unchanged. Use the separate `PBGC-Scaffold-Test-v0.1.2` test root.
- No automatic renaming, template filling, register updates, historical capture, or shortcut repair added; these remain future work.
- Validation: PowerShell syntax parsed successfully; all parameter help sections, five naming-map entries, versioned test root, and retained exclusive file creation checked. Actual Windows/COM execution remains pending.

## 0.1.1 — 2026-10-16

- Add `Case-Filenames.json` with the required stems `<case>R1`, `<case>R5`, `<case>R0`, `<case>PF`, and `<case>V1`, and their authoritative folders.
- Add `File-Naming.txt` explaining completed case file naming, preservation of actual extensions, shared master templates, historical versions, and shortcuts.
- Identify R0 as the package index; retain active PF/V1 in the ACTWORK case root.
- Keep original master template names and preserve all existing case files; this scaffolding release does not rename files or fill templates.
- Use a separate `PBGC-Scaffold-Test-v0.1.1` test root. Version 0.1.0 remains available unchanged.
- Validation: PowerShell tree-sitter syntax parse and all five map entries checked. Windows execution of 0.1.1 still requires a user test. Version 0.1.0 was run successfully on the user's office Windows machine.

## 0.1.0 — 2026-10-16

- Initial folders, purpose README files, empty case register, scaffold identity files, Windows navigation shortcuts, TEMP test mode, and WhatIf preview.
