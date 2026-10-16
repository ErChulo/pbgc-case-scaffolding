#!/usr/bin/env bash
# PBGC case scaffold v0.2.0 for Linux, macOS and WSL.
# Requires Bash and Python 3.8+. Run: bash new-pbgc-case-v0.2.0.sh --help
# Uses directory symlinks, not Windows .lnk files. No runtime network access.
set -euo pipefail
if ! command -v python3 >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: Python 3.8+ (python3) is required.' >&2
    exit 1
fi
python3 - "$@" <<'PY'
import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile

VERSION = "0.2.0"
if sys.version_info < (3, 8):
    sys.exit("ERROR: Python 3.8+ is required.")
if os.name == "nt":
    sys.exit("ERROR: Use the CMD/PowerShell version on Windows. This Bash version supports Linux, macOS and WSL.")

p = argparse.ArgumentParser(
    description="PBGC case scaffolding v0.2.0. You supply the case identity; nothing is inferred.",
    epilog="Real cases require --case-number, --short-name, --documents-root and --actwork-root. Test mode writes only inside the OS temporary directory.",
)
p.add_argument("--version", action="version", version=VERSION)
p.add_argument("--test-mode", "-TestMode", action="store_true")
p.add_argument("--what-if", "-WhatIf", action="store_true")
p.add_argument("--case-number", "-CaseNumber")
p.add_argument("--short-name", "-ShortName")
p.add_argument("--documents-root", "--onedrive-root", "-OneDriveRoot", dest="documents_root")
p.add_argument("--actwork-root", "-ActWorkRoot")
p.add_argument("--resources-root", "-ResourcesRoot")
p.add_argument("--additional-work-folder", "-AdditionalWorkFolder", action="append", default=[])
args = p.parse_args()


def valid_name(name):
    if (not name or not name.strip() or name in (".", "..") or
        re.search(r'[<>:"/\\|?*\x00-\x1f]', name) or name.endswith((".", " ")) or
        re.match(r"^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)", name, re.I)):
        raise ValueError("Invalid folder name: " + repr(name))


def absolute(value):
    return Path(os.path.abspath(os.path.expanduser(value)))


def exists(path):
    # Include broken symlinks: never replace them silently.
    return os.path.lexists(str(path))


def require_real_directory(path):
    if exists(path) and (path.is_symlink() or not path.is_dir()):
        raise ValueError("Expected a real directory: " + str(path))


def require_regular_file(path):
    if exists(path) and (path.is_symlink() or not path.is_file()):
        raise ValueError("Expected a regular file: " + str(path))


def write_new(path, text):
    if exists(path):
        return
    if args.what_if:
        print("What if: create file " + str(path))
    else:
        # Exclusive creation: never truncate an existing work product.
        with path.open("x", encoding="utf-8", newline="\n") as f:
            f.write(text)


def main():
    case_number = args.case_number or "00000000"
    short_name = args.short_name if args.short_name is not None else "Test-Case"
    if not re.fullmatch(r"[0-9]{8}", case_number):
        raise ValueError("Case number must contain exactly eight digits.")
    valid_name(short_name)
    for name in args.additional_work_folder:
        valid_name(name)
    if args.test_mode:
        if any((args.documents_root, args.actwork_root, args.resources_root)):
            raise ValueError("Test mode uses the OS temporary directory only; do not combine it with destination overrides.")
        test_root = Path(tempfile.gettempdir()) / ("PBGC-Scaffold-Test-v" + VERSION)
        documents_root = test_root / "Documents"
        actwork_root = test_root / "ACTWORK"
        resources = test_root / "Actuarial-Resources"
    else:
        if case_number == "00000000" or args.short_name is None:
            raise ValueError("For a real case supply --case-number and --short-name.")
        if not args.documents_root or not args.actwork_root:
            raise ValueError("Supply existing --documents-root and --actwork-root on Linux/macOS/WSL. Windows drive letters are not inferred.")
        documents_root = absolute(args.documents_root)
        actwork_root = absolute(args.actwork_root)
        if not documents_root.is_dir() or not actwork_root.is_dir():
            raise ValueError("The documents and ACTWORK parent directories must already exist.")
        resources = absolute(args.resources_root) if args.resources_root else documents_root / "Actuarial-Resources"

    documents = documents_root / (case_number + "-" + short_name)
    software = actwork_root / case_number
    roots = [documents, software, resources]
    # Resolve existing ancestors too, so aliases cannot hide overlapping roots.
    resolved = [root.resolve() for root in roots]
    for i, a in enumerate(resolved):
        for b in resolved[i + 1:]:
            if a == b or a in b.parents or b in a.parents:
                raise ValueError("Case, software and resources roots must be separate, non-nested directories.")

    identity = dict(CaseNumber=case_number, ShortName=short_name,
                    DocumentsPath=str(documents), SoftwarePath=str(software), ResourcesPath=str(resources))
    for root in (documents, software):
        require_real_directory(root)
        marker = root / "Scaffold.json"
        require_regular_file(marker)
        if exists(root):
            if marker.is_file():
                saved = json.loads(marker.read_text(encoding="utf-8-sig"))
                if not isinstance(saved, dict) or any(saved.get(k) != identity[k] for k in
                        ("CaseNumber", "DocumentsPath", "SoftwarePath", "ResourcesPath")):
                    raise ValueError("Existing scaffold configuration differs: " + str(marker))
            elif any(root.iterdir()):
                raise ValueError("Existing nonempty case has no scaffold marker. No changes made: " + str(root))

    folders = {
        documents: "Case " + case_number + " - " + short_name + ". You supplied this identity. See Scaffold.json, File-Naming.txt and Usage-v0.2.0.txt. Store each authoritative file once; use links elsewhere.",
        documents / "Sources": "Unaltered received plan documents, amendments, valuations, census deliveries, Form 5500s and Image Viewer records. Store each source once.",
        documents / "Work": "Current case-specific work. Each document has one authoritative location. Add folders only when needed.",
        documents / "Work/Upfront": "Current AMB acceptance, R5/plan summary, DEL, section 436, estimated adjustment and administration documents. R5 stem: " + case_number + "R5. Shared blank masters remain in Templates.",
        documents / "Work/Data": "Working exports, prepared inputs, reconciliations and corrections. Unaltered deliveries remain in Sources.",
        documents / "Work/BET": "Benefit estimate calculators, participant calculations, testing and outputs. Distinct scenarios are separate work products.",
        documents / "Work/Actuarial": "Supporting calculations, factors, listings, validation, statements, R1/case memo and CMS reports. R1 stem: " + case_number + "R1. Active PF/V1 remain at the ACTWORK root.",
        documents / "Reviews": "Create one folder per review as needed. Link to exact preserved versions; retain comments, responses and submission evidence. External recipients need actual files if they cannot access the link targets.",
        documents / "Closeout": "Authoritative R0 package index, stem " + case_number + "R0; links to approved work products and closeout evidence. External submissions require actual files, not local links.",
        documents / "History": "Earlier document versions, preserved once. Never edit a version referenced by a completed review. Version capture and link repair are not automatic.",
        software: "Active PF and V1 retain their required root paths and stems " + case_number + "PF and " + case_number + "V1. No empty workbooks or configuration files are generated.",
        software / "BSRS": "BSRS files at application-required paths. Confirm the BR, BS and BSR_TEST layout before use.",
        software / "History": "Previous software versions preserved once. Retain matching V1/PF/configuration sets for significant runs. Capture is not automatic.",
        resources: "Resources shared across cases. Maintain master templates and reference material here instead of copying them into every case.",
        resources / "Templates": "Shared blank masters with original filenames retained. Create case-specific documents when needed. Never edit or rename the shared master. Templates are not included.",
        resources / "Reference": "Reusable guidance, sample language, examples and supporting documentation shared across cases.",
        resources / "PowerShell": "Permanent master scripts and shell launchers. Run from an approved location. Do not store case data here.",
    }
    for name in ("BR", "BS", "BSR_TEST"):
        folders[software / "BSRS" / name] = "BSRS " + name + " files. Preserve required filenames and internal relationships."
    for name in args.additional_work_folder:
        folders.setdefault(documents / "Work" / name, "Additional case work: " + name + ". Store authoritative files here and use links elsewhere. Update this README for its purpose.")

    mapping = {"R1": documents / "Work/Actuarial", "R5": documents / "Work/Upfront",
               "R0": documents / "Closeout", "PF": software, "V1": software}
    filenames = dict(SchemaVersion="1.0", ScaffoldVersion=VERSION, CaseNumber=case_number,
                     Files=[dict(Code=code, FileStem=case_number + code, Folder=str(folder))
                            for code, folder in mapping.items()])
    config = dict(identity, ScaffoldVersion=VERSION, TestMode=args.test_mode, Platform=sys.platform)
    from datetime import datetime, timezone
    config["CreatedUtc"] = datetime.now(timezone.utc).isoformat()
    naming = "Case file naming - scaffold v" + VERSION + "\n\n"
    naming += "Keep shared blank masters unchanged under their original names. After entering case information, save completed files with these stems:\n"
    naming += "\n".join(case_number + code + " - " + str(folder) for code, folder in mapping.items())
    naming += "\n\nR0 is the package index. The number immediately precedes the code: no spaces or separators.\nPreserve the actual file extension; renaming does not convert formats.\nKeep date/version labels out of current required names; preserve earlier versions in History.\nLink to exact preserved versions for completed reviews. Capture and link repair are not automatic.\nThis scaffold does not fill templates or rename existing files.\n"
    usage = "PBGC case scaffold v" + VERSION + "\n\n" + "\n".join(k + ": " + str(v) for k, v in identity.items())
    usage += "\n\nYou supply --case-number and --short-name. Nothing is inferred.\nPreview: bash new-pbgc-case-v0.2.0.sh --test-mode --what-if\nTest: bash new-pbgc-case-v0.2.0.sh --test-mode\nReal cases additionally require existing --documents-root and --actwork-root.\nUse --help for parameters. Re-run with the same identity and roots.\n--additional-work-folder adds one folder; repeat the option for more folders.\nExisting files are preserved. No renaming, automatic history, register updates or link repair.\nLinux/macOS/WSL use directory symlinks; Windows .lnk files are not generated.\nWindows applications still require their actual Windows software paths.\n"
    files = {folder / "README.txt": purpose + "\n" for folder, purpose in folders.items()}
    files.update({documents / "Scaffold.json": json.dumps(config, indent=2) + "\n",
                  software / "Scaffold.json": json.dumps(config, indent=2) + "\n",
                  documents / "Case-Filenames.json": json.dumps(filenames, indent=2) + "\n",
                  documents / "File-Naming.txt": naming,
                  documents / "Usage-v0.2.0.txt": usage,
                  documents / "Case-Register.csv": '"FileId","Purpose","AuthoritativePath","Version","Status"\n'})
    links = {documents / "ACTWORK": software, documents / "Templates": resources / "Templates",
             software / "Case-Documents": documents}

    # Full preflight before any directory or file is created.
    for folder in folders:
        require_real_directory(folder)
    for file in files:
        require_regular_file(file)
    for link, target in links.items():
        if exists(link) and (not link.is_symlink() or os.readlink(str(link)) != str(target)):
            raise ValueError("Existing link has a different type or target: " + str(link))

    for i, folder in enumerate(folders, 1):
        if args.what_if:
            if not exists(folder):
                print("What if: create directory " + str(folder))
        else:
            if sys.stderr.isatty():
                print("\rCreating scaffold: %d/%d" % (i, len(folders)), end="", file=sys.stderr, flush=True)
            folder.mkdir(parents=True, exist_ok=True)
    for path, content in files.items():
        write_new(path, content)
    for link, target in links.items():
        if not exists(link):
            if args.what_if:
                print("What if: create link " + str(link) + " -> " + str(target))
            else:
                link.symlink_to(target, target_is_directory=True)
    if not args.what_if:
        print("\nScaffold complete." if sys.stderr.isatty() else "Scaffold complete.", file=sys.stderr)
    print(json.dumps(dict(Version=VERSION, Preview=args.what_if, Documents=str(documents),
                          Software=str(software), Resources=str(resources)), indent=2))


try:
    main()
except (OSError, ValueError) as exc:
    print("ERROR: " + str(exc), file=sys.stderr)
    sys.exit(1)
PY
