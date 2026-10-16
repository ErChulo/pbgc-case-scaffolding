"""Template content integrity and version 0.2.1 shared-resource integration."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "new-pbgc-case-v0.2.1.sh"


class TemplateBundleTests(unittest.TestCase):
    def test_catalog_matches_all_original_files(self):
        folder = ROOT / "Actuarial-Resources/Templates"
        catalog = json.loads((folder / "catalog.json").read_text())
        self.assertEqual(len(catalog["Files"]), 8)
        for entry in catalog["Files"]:
            data = (folder / entry["FileName"]).read_bytes()
            self.assertEqual(len(data), entry["SizeBytes"])
            self.assertEqual(hashlib.sha256(data).hexdigest(), entry["SHA256"])
        self.assertFalse((folder / "Actuarial Case Report Checklist (January 2024).pdf").exists())

    def test_bundle_detected_for_real_case_without_copying_masters(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            clone = root / "clone"
            templates = clone / "Actuarial-Resources/Templates"
            templates.mkdir(parents=True)
            (templates / "catalog.json").write_text('{"Files": []}')
            (templates / "original.docx").write_bytes(b"master")
            shutil.copyfile(SCRIPT, clone / SCRIPT.name)
            docs, act = root / "docs", root / "act"
            docs.mkdir()
            act.mkdir()
            cmd = ["bash", str(clone / SCRIPT.name), "--case-number", "12345678",
                   "--short-name", "Demo", "--documents-root", str(docs), "--actwork-root", str(act)]
            result = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            summary = json.loads(result.stdout)
            self.assertEqual(summary["Resources"], str(clone / "Actuarial-Resources"))
            self.assertEqual((docs / "12345678-Demo/Templates").resolve(), templates)
            self.assertEqual((templates / "original.docx").read_bytes(), b"master")
            self.assertFalse((docs / "Actuarial-Resources").exists())

    def test_new_version_temp_preview_and_rerun(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp).resolve()
            env = dict(os.environ, TMPDIR=temp, TEMP=temp, TMP=temp)
            cmd = ["bash", str(SCRIPT), "--test-mode"]
            preview = subprocess.run(cmd + ["--what-if"], env=env, capture_output=True, text=True)
            self.assertEqual(preview.returncode, 0, preview.stderr)
            self.assertEqual(list(root.iterdir()), [])
            result = subprocess.run(cmd, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            summary = json.loads(result.stdout)
            resources = Path(summary["Resources"])
            self.assertEqual(resources, root / "PBGC-Scaffold-Test-v0.2.1/Actuarial-Resources")
            self.assertFalse((resources / "Templates/catalog.json").exists())
            file = Path(summary["Documents"]) / "Scaffold.json"
            before = file.read_bytes()
            again = subprocess.run(cmd, env=env, capture_output=True, text=True)
            self.assertEqual(again.returncode, 0, again.stderr)
            self.assertEqual(file.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
