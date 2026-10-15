"""Release lifecycle tests with a fake GitHub API; no remote mutations."""
import importlib.util
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("release_draft", ROOT / "scripts/release_draft.py")
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)
REVISION = "a" * 40


class FakeGitHub:
    def __init__(self, draft=True, exists=True, target=None):
        self.saved = {"id": 7, "tag_name": "v2.0.0", "draft": draft,
                      "name": "My title", "body": "My manually edited notes",
                      "target_commitish": "master", "html_url": "https://github.com/example/project/releases/7"}
        self.releases = [self.saved] if exists else []
        self.target = target
        self.writes = []
        self.uploads = []
        self.denied = None
        self.publish_during_build = False

    def api(self, path, method="GET", payload=None):
        if method != "GET":
            self.writes.append((path, payload))
            if path == "git/refs":
                self.target = {"type": "commit", "sha": payload["sha"]}
                return {}
            if path == "releases":
                self.saved = dict(self.saved, **payload)
                self.releases = [self.saved]
                return self.saved
            raise AssertionError(path)
        if path.startswith("releases?"):
            return self.releases
        if path.startswith("git/ref/"):
            if self.denied:
                raise release.APIError(self.denied, "denied")
            if self.target is None:
                raise release.APIError(404, "not found")
            return {"object": self.target}
        if path.startswith("git/tags/"):
            return {"object": {"type": "commit", "sha": REVISION}}
        if path == "releases/7":
            return dict(self.saved, draft=False) if self.publish_during_build else self.saved
        raise AssertionError(path)

    def upload(self, tag, assets):
        self.uploads.append((tag, [p.name for p in assets]))


class ReleaseDraftTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.assets = self.root / "dist"
        self.assets.mkdir()
        (self.assets / "RELEASE-NOTES.md").write_text("Generated release notes")
        (self.assets / "package.deb").write_text("package")
        (self.root / "VERSION").write_text("2.0.0\n")
        (self.root / "CHANGELOG.md").write_text("## 2.0.0 — 2026-10-15\n")
        (self.root / "docs/releases").mkdir(parents=True)
        (self.root / "docs/releases/2.0.0.md").write_text("notes")
        root_patch = patch.object(release, "ROOT", self.root)
        root_patch.start()
        self.addCleanup(root_patch.stop)

    def populate(self, client):
        return release.populate(client, "v2.0.0", REVISION, self.assets)

    def test_manual_draft_requires_master_and_matching_tag(self):
        self.assertEqual(release.validate_request("workflow_dispatch", "refs/heads/master", "create-draft", "v2.0.0"), (True, "v2.0.0"))
        for ref, tag in [("refs/heads/feature", "v2.0.0"), ("refs/heads/master", ""),
                         ("refs/heads/master", "v9.0.0"), ("refs/heads/master", "v2.0.0\nmalicious")]:
            with self.subTest(ref=ref, tag=tag), self.assertRaises(ValueError):
                release.validate_request("workflow_dispatch", ref, "create-draft", tag)

    def test_preview_is_read_only_even_on_a_feature_branch(self):
        self.assertEqual(release.validate_request("workflow_dispatch", "refs/heads/feature", "preview", ""), (False, ""))

    def test_cli_tag_push_keeps_working(self):
        self.assertEqual(release.validate_request("push", "refs/tags/v2.0.0", "preview", ""), (True, "v2.0.0"))
        with self.assertRaises(ValueError):
            release.validate_request("push", "refs/tags/v9.0.0", "preview", "")

    def test_unreleased_and_invalid_date_refused(self):
        for heading in ["## 2.0.0 — unreleased", "## 2.0.0 — 2026-02-30"]:
            (self.root / "CHANGELOG.md").write_text(heading + "\n")
            with self.assertRaises(ValueError):
                release.validate_request("workflow_dispatch", "refs/heads/master", "create-draft", "v2.0.0")

    def test_saved_draft_notes_title_and_id_preserved(self):
        client = FakeGitHub()
        before = dict(client.saved)
        self.populate(client)
        self.assertEqual(client.saved, before)
        self.assertEqual(client.writes, [("git/refs", {"ref": "refs/tags/v2.0.0", "sha": REVISION})])
        self.assertEqual(client.uploads[0][0], "v2.0.0")
        self.assertIn("package.deb", client.uploads[0][1])

    def test_new_draft_uses_authored_notes_and_stays_unpublished(self):
        client = FakeGitHub(exists=False)
        self.populate(client)
        self.assertTrue(client.saved["draft"])
        self.assertEqual(client.saved["body"], "Generated release notes")
        self.assertEqual(client.saved["target_commitish"], REVISION)

    def test_matching_tag_retry_does_not_recreate_tag_or_draft(self):
        client = FakeGitHub(target={"type": "commit", "sha": REVISION})
        self.populate(client)
        self.populate(client)
        self.assertEqual(client.writes, [])
        self.assertEqual(len(client.uploads), 2)

    def test_annotated_tag_is_peeled_to_commit(self):
        client = FakeGitHub(target={"type": "tag", "sha": "b" * 40})
        self.populate(client)
        self.assertEqual(client.writes, [])
        self.assertEqual(len(client.uploads), 1)

    def test_conflicting_tag_never_moved(self):
        client = FakeGitHub(target={"type": "commit", "sha": "b" * 40})
        with self.assertRaisesRegex(ValueError, "different commit"):
            self.populate(client)
        self.assertEqual(client.writes + client.uploads, [])

    def test_published_release_refused_before_tag_creation(self):
        client = FakeGitHub(draft=False)
        with self.assertRaisesRegex(ValueError, "already published"):
            self.populate(client)
        self.assertEqual(client.writes + client.uploads, [])

    def test_api_permission_error_is_not_treated_as_missing_tag(self):
        client = FakeGitHub()
        client.denied = 403
        with self.assertRaises(release.APIError):
            self.populate(client)
        self.assertEqual(client.writes + client.uploads, [])

    def test_publish_during_build_prevents_upload(self):
        client = FakeGitHub(target={"type": "commit", "sha": REVISION})
        client.publish_during_build = True
        with self.assertRaisesRegex(ValueError, "published during"):
            self.populate(client)
        self.assertEqual(client.writes + client.uploads, [])

    def test_draft_target_mismatch_and_duplicate_drafts_refused(self):
        client = FakeGitHub()
        client.saved["target_commitish"] = "another-branch"
        with self.assertRaisesRegex(ValueError, "another revision"):
            self.populate(client)
        client.releases.append(dict(client.saved, id=8))
        with self.assertRaisesRegex(ValueError, "Multiple releases"):
            self.populate(client)
        self.assertEqual(client.writes + client.uploads, [])

    def test_cli_adapter_preserves_json_and_uses_explicit_methods(self):
        response = SimpleNamespace(returncode=0, stdout='HTTP/2.0 201 Created\r\n\r\n{"id":7}', stderr="")
        with patch.object(release.subprocess, "run", return_value=response) as run:
            client = release.GitHub("example/project")
            self.assertEqual(client.api("releases", "POST", {"body": "notes\nwith quotes ' and $"}), {"id": 7})
            self.assertEqual(json.loads(run.call_args.kwargs["input"])["body"], "notes\nwith quotes ' and $")
            self.assertIn("POST", run.call_args.args[0])
        denied = SimpleNamespace(returncode=1, stdout='HTTP/2.0 404 Not Found\n\n{}', stderr="not found")
        with patch.object(release.subprocess, "run", return_value=denied):
            with self.assertRaises(release.APIError) as error:
                client.api("git/ref/tags/v2.0.0")
            self.assertEqual(error.exception.status, 404)


if __name__ == "__main__":
    unittest.main()
