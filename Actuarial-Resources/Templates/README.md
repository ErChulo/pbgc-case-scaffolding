# Shared template collection

Bundle **1.0.0**, imported 2026-10-16. Eight original attachments are stored here unchanged, including the checklist and sample language. A normal clone downloads the actual files; there are no external download links or Git LFS pointers.

| Original filename | Use |
|---|---|
| Plan Summary Shell.docx | R5 plan summary |
| AMB Acceptance Template.docx | AMB acceptance |
| Estimated Benefit Adjustments Worksheet.docx | Estimated adjustment worksheet |
| Actuarial Case Memo Shell_08062026.doc | R1 case memo shell |
| Actuarial Case Memo Sample Language_06042026.docx | Reference language |
| 436 Evaluation (ASTD Updates Nov 2025).docx | Section 436 evaluation |
| Software Closeout Request Email Template.docx | Software closeout request |
| Software Closeout Review Checklist.pdf | Software closeout checklist |

Use `catalog.json` for sizes, SHA-256 hashes, roles and work folders. Master names/extensions are unchanged. Git history and bundle revisions track updates; completed case files follow the case naming map.

The received Actuarial Case Report Checklist (January 2024).pdf is a completed, digitally signed case document. It is not published here or modified into a blank template. Its inclusion or replacement requires further direction.

This collection is not exhaustive. The email did not contain separate estimated administration/adjustment memo masters, an R0 index master, a PF workbook master, or a V1 workbook master. No dummy substitutes are supplied. These are user-supplied files, not asserted to be the latest official revisions.

For real cases, scripts 0.2.1 detect this adjacent resources folder. Case links point here; masters are not copied among cases. If running a script copied to TEMP, pass the clone's original resources folder explicitly through `-ResourcesRoot` (PowerShell/CMD) or `--resources-root` (Bash). Test mode keeps an isolated TEMP resources folder and does not copy the real masters. Keep the clone at a stable path so links remain valid.
