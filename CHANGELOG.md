# Changelog

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
