"""Exercise release collection failures before any tag or publishing credentials."""
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("release_assets", ROOT / "scripts/release_assets.py")
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)


class ReleaseAssetsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source, self.output = self.root / "collected", self.root / "dist"
        for name, patterns in release.REQUIRED.items():
            directory = self.source / ("package-" + name)
            directory.mkdir(parents=True)
            for pattern in patterns:
                (directory / pattern.replace("*", "2.0.0")).write_text("package fixture")
            (directory / "SHA256SUMS").write_text("old per-bundle checksums")

    def collect(self):
        return release.assemble(self.source, self.output, "a" * 40)

    def test_complete_matrix_has_unique_assets_notes_and_verified_checksums(self):
        self.assertGreater(self.collect(), 13)
        self.assertIn("a" * 40, (self.output / "BUILD-REPORT.md").read_text())
        self.assertTrue((self.output / "RELEASE-NOTES.md").is_file())
        lines = (self.output / "SHA256SUMS").read_text().splitlines()
        self.assertEqual(len(lines), len(list(self.output.iterdir())) - 1)
        for line in lines:
            digest, name = line.split("  ")
            self.assertEqual(digest, hashlib.sha256((self.output / name).read_bytes()).hexdigest())

    def test_missing_required_package_fails_before_output(self):
        next((self.source / "package-deb").glob("*.deb")).unlink()
        with self.assertRaisesRegex(ValueError, "Missing deb asset"):
            self.collect()
        self.assertFalse(self.output.exists())

    def test_duplicate_filename_is_not_silently_overwritten(self):
        (self.source / "package-deb" / "flake.nix").write_text("collision")
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            self.collect()

    def test_symlink_asset_rejected(self):
        (self.source / "package-deb" / "secret").symlink_to(ROOT / "VERSION")
        with self.assertRaisesRegex(ValueError, "Symlink"):
            self.collect()

    def test_empty_asset_rejected(self):
        (self.source / "package-nix" / "flake.nix").write_text("")
        with self.assertRaisesRegex(ValueError, "Empty asset"):
            self.collect()

    def test_existing_output_and_non_commit_revision_rejected(self):
        self.output.mkdir()
        (self.output / "keep.txt").write_text("retain")
        with self.assertRaisesRegex(ValueError, "empty output"):
            self.collect()
        with self.assertRaisesRegex(ValueError, "exact source commit"):
            release.assemble(self.source, self.root / "other", "master")
        self.assertEqual((self.output / "keep.txt").read_text(), "retain")


if __name__ == "__main__":
    unittest.main()
