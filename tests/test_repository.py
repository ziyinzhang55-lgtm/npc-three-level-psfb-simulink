from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.check_repository import audit


def _windows_path(*parts):
    return "\\".join(parts)


class RepositoryAuditTests(unittest.TestCase):
    def test_empty_repository_reports_missing_public_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            errors = audit(Path(tmp))
        self.assertTrue(any("README.md" in error for error in errors))

    def test_absolute_windows_path_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "README.md").write_text(
                _windows_path("C:", "Users", "local", "file"), encoding="utf-8"
            )
            errors = audit(root, require_layout=False)
        self.assertTrue(any("absolute path" in error for error in errors))

    def test_slx_embedded_absolute_path_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            model = root / "model.slx"
            with zipfile.ZipFile(model, "w") as archive:
                archive.writestr(
                    "simulink/blockdiagram.xml",
                    _windows_path("D:", "project", "model"),
                )
            errors = audit(root, require_layout=False)
        self.assertTrue(any("model.slx" in error for error in errors))

    def test_slx_author_metadata_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            model = root / "model.slx"
            core_properties = """<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties
    xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
    xmlns:dc="http://purl.org/dc/elements/1.1/">
  <dc:creator>local-user</dc:creator>
  <cp:lastModifiedBy>local-user</cp:lastModifiedBy>
</cp:coreProperties>
"""
            with zipfile.ZipFile(model, "w") as archive:
                archive.writestr("metadata/coreProperties.xml", core_properties)

            errors = audit(root, require_layout=False)

        self.assertTrue(any("non-public SLX author metadata" in error
                            for error in errors))

    def test_complete_clean_repository_passes_and_ignored_paths_are_skipped(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "model").mkdir()
            (root / "scripts").mkdir()
            (root / "docs").mkdir()
            (root / "README.md").write_text("Public repository", encoding="utf-8")
            (root / "scripts/run_all.m").write_text("disp('run');", encoding="utf-8")
            (root / "docs/design-report.pdf").write_bytes(b"%PDF-clean")
            with zipfile.ZipFile(root / "model/npc_tl_psfb_cdr_final.slx", "w") as archive:
                archive.writestr("simulink/blockdiagram.xml", "<model />")

            forbidden = _windows_path("C:", "Users", "private", "file")
            for directory in (".git", ".superpowers", "docs/superpowers"):
                ignored = root / directory
                ignored.mkdir(parents=True)
                (ignored / "notes.txt").write_text(forbidden, encoding="utf-8")

            self.assertEqual([], audit(root))

    def test_checker_source_does_not_embed_forbidden_literals(self):
        checker = Path(__file__).resolve().parents[1] / "tools/check_repository.py"
        source = checker.read_text(encoding="utf-8")
        forbidden_literals = (
            _windows_path("C:", "Users"),
            _windows_path("D:", ""),
            "WeChat" + " " + "Files",
        )
        for literal in forbidden_literals:
            self.assertNotIn(literal, source)

    def test_extended_text_extensions_are_scanned(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            payload = (
                _windows_path("C:", "Users", "local", "file")
                + "\n"
                + "WeChat" + " " + "Files"
            )
            extensions = (".json", ".yaml", ".yml", ".xml", ".prj")
            for extension in extensions:
                (root / f"fixture{extension}").write_text(payload, encoding="utf-8")

            errors = audit(root, require_layout=False)

        for extension in extensions:
            self.assertTrue(any(f"fixture{extension}" in error for error in errors))
        self.assertTrue(any("messaging path" in error for error in errors))

    def test_corrupt_slx_is_reported_as_invalid_model(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            model = root / "corrupt.slx"
            model.write_bytes(b"not a ZIP archive")

            errors = audit(root, require_layout=False)

        self.assertTrue(any("corrupt.slx" in error and "invalid SLX archive" in error
                            for error in errors))

    def test_readme_prepares_soft_switching_artifact_before_default_check(self):
        readme = (Path(__file__).resolve().parents[1] / "README.md").read_text(
            encoding="utf-8"
        )
        generator = "run_npc_tl_psfb_verification(12e-3,true);"
        verifier = "verify_npc_soft_switching();"

        self.assertIn(generator, readme)
        self.assertLess(readme.index(generator), readme.index(verifier))


if __name__ == "__main__":
    unittest.main()
