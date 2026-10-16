"""Offline behavioral tests for the standalone Bash launcher; no extra packages."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "new-pbgc-case-v0.2.0.sh"


class BashScaffoldTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="pbgc-scaffold-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.env = dict(os.environ, TMPDIR=str(self.root), TMP=str(self.root), TEMP=str(self.root))

    def run_script(self, *args, ok=True):
        result = subprocess.run(["bash", str(SCRIPT), *args], cwd=self.root,
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def scaffold_paths(self):
        base = self.root / "PBGC-Scaffold-Test-v0.2.0"
        return base, base / "Documents/00000000-Test-Case", base / "ACTWORK/00000000"

    def snapshot(self):
        data = {}
        for path in sorted(self.root.rglob("*")):
            relative = str(path.relative_to(self.root))
            if path.is_symlink():
                data[relative] = ("link", os.readlink(path))
            elif path.is_file():
                data[relative] = ("file", hashlib.sha256(path.read_bytes()).hexdigest(), path.stat().st_mtime_ns)
            else:
                data[relative] = ("directory",)
        return data

    def test_help_and_version_do_not_write(self):
        self.assertIn("--case-number", self.run_script("--help").stdout)
        self.assertEqual(self.run_script("--version").stdout.strip(), "0.2.0")
        self.assertEqual(list(self.root.iterdir()), [])

    def test_preview_does_not_write(self):
        output = self.run_script("--test-mode", "--what-if").stdout
        self.assertIn('"Preview": true', output)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_generated_tree_naming_links_and_instructions(self):
        result = self.run_script("--test-mode")
        summary = json.loads(result.stdout)
        base, documents, software = self.scaffold_paths()
        self.assertEqual(summary["Documents"], str(documents))
        self.assertTrue((documents / "Work/Upfront/README.txt").is_file())
        self.assertTrue((software / "BSRS/BSR_TEST/README.txt").is_file())
        for path in base.rglob("*"):
            if path.is_dir() and not path.is_symlink() and path not in (base / "Documents", base / "ACTWORK"):
                self.assertTrue((path / "README.txt").is_file(), str(path))
        mapping = json.loads((documents / "Case-Filenames.json").read_text())
        self.assertEqual([x["FileStem"] for x in mapping["Files"]],
                         ["00000000" + code for code in ("R1", "R5", "R0", "PF", "V1")])
        self.assertEqual((documents / "ACTWORK").resolve(), software)
        self.assertEqual((documents / "Templates").resolve(), base / "Actuarial-Resources/Templates")
        self.assertEqual((software / "Case-Documents").resolve(), documents)
        self.assertIn("--case-number", (documents / "Usage-v0.2.0.txt").read_text())
        self.assertEqual(list(base.rglob("*.xlsx")), [])

    def test_rerun_preserves_files_masters_and_timestamps(self):
        self.run_script("--test-mode")
        base, documents, _ = self.scaffold_paths()
        (documents / "README.txt").write_text("User-customized README")
        (base / "Actuarial-Resources/Templates/master.docx").write_bytes(b"original master")
        before = self.snapshot()
        self.run_script("--test-mode")
        self.assertEqual(self.snapshot(), before)

    def test_named_case_in_temp_and_extra_work_folders(self):
        self.run_script("-TestMode", "-CaseNumber", "12345678", "-ShortName", "Demo Plan",
                        "--additional-work-folder", "Special Work", "--additional-work-folder", "Work2")
        docs = self.root / "PBGC-Scaffold-Test-v0.2.0/Documents/12345678-Demo Plan"
        self.assertTrue((docs / "Work/Special Work/README.txt").is_file())
        config = json.loads((docs / "Scaffold.json").read_text())
        self.assertEqual(config["CaseNumber"], "12345678")
        self.assertEqual(config["ShortName"], "Demo Plan")
        self.assertIn("12345678R1", (docs / "File-Naming.txt").read_text())

    def test_real_case_explicit_posix_roots_with_spaces(self):
        docs = self.root / "document parent"
        software = self.root / "software parent"
        docs.mkdir()
        software.mkdir()
        self.run_script("--case-number", "12345678", "--short-name", "Demo",
                        "--documents-root", str(docs), "--actwork-root", str(software))
        self.assertTrue((docs / "12345678-Demo/Scaffold.json").is_file())
        self.assertTrue((software / "12345678/Scaffold.json").is_file())

    def test_invalid_names_and_numbers_fail_without_writes(self):
        for args in [("--case-number", "123"), ("--case-number", "abcdefgh"),
                     ("--short-name", "../escape"), ("--short-name", "NUL"),
                     ("--short-name", ""), ("--additional-work-folder", "a/b")]:
            self.run_script("--test-mode", *args, ok=False)
            self.assertEqual(list(self.root.iterdir()), [])

    def test_test_mode_rejects_root_override(self):
        self.run_script("--test-mode", "--documents-root", str(self.root), ok=False)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_real_case_requires_identity_and_explicit_roots(self):
        self.run_script(ok=False)
        self.run_script("--case-number", "12345678", "--short-name", "Demo", ok=False)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_unmanaged_nonempty_case_is_refused(self):
        _, documents, _ = self.scaffold_paths()
        documents.mkdir(parents=True)
        (documents / "user-file.txt").write_text("preserve")
        before = self.snapshot()
        self.run_script("--test-mode", ok=False)
        self.assertEqual(self.snapshot(), before)

    def test_conflicting_shortcut_is_refused_without_changes(self):
        self.run_script("--test-mode")
        _, documents, _ = self.scaffold_paths()
        (documents / "ACTWORK").unlink()
        (documents / "ACTWORK").symlink_to(self.root / "nonexistent")
        before = self.snapshot()
        self.run_script("--test-mode", ok=False)
        self.assertEqual(self.snapshot(), before)

    def test_conflicting_marker_is_refused(self):
        self.run_script("--test-mode")
        _, documents, _ = self.scaffold_paths()
        marker = documents / "Scaffold.json"
        data = json.loads(marker.read_text())
        data["CaseNumber"] = "87654321"
        marker.write_text(json.dumps(data))
        before = self.snapshot()
        self.run_script("--test-mode", ok=False)
        self.assertEqual(self.snapshot(), before)

    def test_readme_symlink_is_refused_without_touching_target(self):
        self.run_script("--test-mode")
        _, documents, _ = self.scaffold_paths()
        target = self.root / "external.txt"
        target.write_text("preserve external")
        (documents / "README.txt").unlink()
        (documents / "README.txt").symlink_to(target)
        before = self.snapshot()
        self.run_script("--test-mode", ok=False)
        self.assertEqual(self.snapshot(), before)

    def test_nested_roots_are_refused(self):
        self.root.joinpath("docs").mkdir()
        self.root.joinpath("actwork").mkdir()
        before = self.snapshot()
        self.run_script("--case-number", "12345678", "--short-name", "Demo",
                        "--documents-root", str(self.root / "docs"),
                        "--actwork-root", str(self.root / "actwork"),
                        "--resources-root", str(self.root / "docs/12345678-Demo/nested"), ok=False)
        self.assertEqual(self.snapshot(), before)


if __name__ == "__main__":
    unittest.main()
