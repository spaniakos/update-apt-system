"""Wiki rendering and local Git publishing tests; no network or credentials."""
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("wiki", ROOT / "scripts/wiki.py")
wiki = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(wiki)


class WikiTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="updateself wiki ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.output = self.root / "pages"

    def test_all_pages_and_readme_targets_exist(self):
        names = wiki.build(self.output, "test-source-ref")
        self.assertIn("Home.md", names)
        self.assertIn("_Sidebar.md", names)
        self.assertIn("_Footer.md", names)
        slugs = {Path(n).stem for n in names}
        for text in [p.read_text() for p in self.output.glob("*.md")]:
            for match in wiki.WIKILINK.finditer(text):
                self.assertIn(match.group(1).rsplit("|", 1)[-1], slugs)
        for slug in re.findall(r"github.com/spaniakos/update-apt-system/wiki/([A-Za-z0-9_-]+)", (ROOT / "README.md").read_text()):
            self.assertIn(slug, slugs)
        home = (self.output / "Home.md").read_text()
        self.assertIn("Documentation for **updateself 2.0.0**.", home)
        self.assertNotIn("2.0.0 (unreleased)", home)
        self.assertIn("test-source-ref", home)

    def test_document_links_become_wiki_or_pinned_source_links(self):
        sources = {"Installation": Path("docs/INSTALL.md")}
        result = wiki.rewrite_links("[Install](INSTALL.md) [Policy](../SECURITY.md)", Path("docs/CLI.md"), sources, "spaniakos/update-apt-system", "abc123")
        self.assertIn("/wiki/Installation", result)
        self.assertIn("/blob/abc123/SECURITY.md", result)
        with self.assertRaises(ValueError):
            wiki.rewrite_links("[Broken](missing.md)", Path("docs/CLI.md"), sources, "spaniakos/update-apt-system", "abc123")

    def test_renderer_is_repeatable_and_refuses_unowned_output(self):
        names = wiki.build(self.output, "abc123")
        self.assertEqual(names, wiki.build(self.output, "abc123"))
        (self.output / "unrelated.txt").write_text("keep")
        with self.assertRaises(ValueError):
            wiki.build(self.output, "abc123")
        self.assertEqual((self.output / "unrelated.txt").read_text(), "keep")

    def test_sync_preserves_manual_pages_and_removes_obsolete_owned_page(self):
        wiki.build(self.output, "abc123")
        checkout = self.root / "checkout"
        (checkout / ".git").mkdir(parents=True)
        (checkout / "Manual.md").write_text("manual notes")
        (checkout / "Old.md").write_text("old generated page")
        (checkout / wiki.MANIFEST).write_text(json.dumps(["Old.md"]))
        wiki.reconcile(self.output, checkout)
        self.assertFalse((checkout / "Old.md").exists())
        self.assertEqual((checkout / "Manual.md").read_text(), "manual notes")
        self.assertTrue((checkout / "Home.md").exists())

    def test_invalid_manifest_and_symlink_rejected(self):
        wiki.build(self.output, "abc123")
        checkout = self.root / "checkout"
        (checkout / ".git").mkdir(parents=True)
        (checkout / wiki.MANIFEST).write_text(json.dumps(["../outside.md"]))
        with self.assertRaises(ValueError):
            wiki.reconcile(self.output, checkout)
        (checkout / wiki.MANIFEST).unlink()
        (checkout / "Home.md").symlink_to(self.root / "outside.md")
        with self.assertRaises(ValueError):
            wiki.reconcile(self.output, checkout)

    def test_publish_to_local_wiki_is_idempotent_and_preserves_manual_pages(self):
        remote, seed = self.root / "wiki.git", self.root / "seed"
        env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        def git(*args):
            return subprocess.check_output(["git", *map(str, args)], env=env, stderr=subprocess.PIPE, text=True).strip()
        git("init", "--bare", "--initial-branch=main", remote)
        git("clone", remote, seed)
        (seed / "Home.md").write_text("initial home")
        (seed / "Manual.md").write_text("retain these notes")
        git("-C", seed, "add", ".")
        git("-C", seed, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-m", "Initialize")
        git("-C", seed, "push", "origin", "HEAD")
        wiki.build(self.output, "abc123")
        cmd = [os.environ.get("BASH_BIN", "bash"), str(ROOT / "scripts/publish-wiki.sh"), str(self.output), str(remote), "abc123"]
        first = subprocess.run(cmd, env=env, capture_output=True, text=True)
        self.assertEqual(first.returncode, 0, first.stderr)
        sha = git("--git-dir", remote, "rev-parse", "HEAD")
        second = subprocess.run(cmd, env=env, capture_output=True, text=True)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("already current", second.stdout)
        self.assertEqual(sha, git("--git-dir", remote, "rev-parse", "HEAD"))
        self.assertEqual(git("--git-dir", remote, "show", "HEAD:Manual.md"), "retain these notes")


if __name__ == "__main__":
    unittest.main()
