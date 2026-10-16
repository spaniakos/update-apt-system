"""Self-management tests use temporary prefixes, stubbed managers and offline releases."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASH = os.environ.get("BASH_BIN", "bash")


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="updateself lifecycle ")
        self.addCleanup(self.tmp.cleanup)
        # macOS resolves /var and /tmp through /private; match production's
        # physical-path ownership comparisons in these temporary fixtures.
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / "source"
        self.source.mkdir()
        for item in ["bin", "man", "completions"]:
            shutil.copytree(ROOT / item, self.source / item)
        for name in ["install.sh", "README.md", "LICENSE"]:
            shutil.copyfile(ROOT / name, self.source / name)
        self.prefix = self.root / "installed"
        self.exe = self.prefix / "bin/updateself"
        self.stubdir = self.root / "stubs"
        self.stubdir.mkdir()
        self.release = self.root / "release"
        self.release.mkdir()
        self.temp = self.root / "tmp"
        self.temp.mkdir()
        self.log = self.root / "calls"
        self.env = dict(os.environ, PATH=f"{self.stubdir}:/usr/bin:/bin", HOME=str(self.root),
                        TMPDIR=str(self.temp), TEST_CALLS=str(self.log), TEST_RELEASE=str(self.release),
                        TEST_OS="Linux", TEST_MAC="0", TEST_LATEST="2.2.0")
        # Instrument the test copy only; production has no platform/privilege bypass.
        script = (self.source / "bin/updateself").read_text().replace("/usr/local/bin/updateself", str(self.exe))
        script = script.replace('"$EUID"', '"${TEST_UID:-0}"')
        (self.source / "bin/updateself").write_text(script)
        self.stub("uname", 'case "$1" in -s) echo "$TEST_OS";; -m) echo arm64;; esac')
        for name in ["dpkg-query", "rpm", "pacman", "apk", "xbps-query", "port", "pkg_info", "pkg"]:
            self.stub(name, "exit 1")
        self.stub("pkgutil", '''case "$1" in
--pkg-info) [ "$TEST_MAC" = 1 ];;
--forget) echo "forget $2" >> "$TEST_CALLS";;
*) exit 1;; esac''')
        self.stub("curl", '''printf 'curl %s\\n' "$*" >> "$TEST_CALLS"
case "$*" in *-fsSLI*) printf 'https://github.com/spaniakos/updateself/releases/tag/v%s' "$TEST_LATEST"; exit;; esac
out=''; url=''
while [ "$#" -gt 0 ]; do
  case "$1" in -o) out=$2; shift 2;; https://*) url=$1; shift;; *) shift;; esac
done
cp "$TEST_RELEASE/${url##*/}" "$out"
''')
        self.stub("gh", 'echo "gh $*" >> "$TEST_CALLS"; exit "${TEST_GH_FAIL:-0}"')
        self.install()

    def stub(self, name, body):
        path = self.stubdir / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def install(self):
        subprocess.run([BASH, str(self.source / "install.sh"), "--system", "--prefix", str(self.prefix)],
                       check=True, env=self.env, capture_output=True)

    def run_script(self, *args, alias=False):
        command = self.prefix / "bin/updsf" if alias else self.exe
        return subprocess.run([BASH, str(command), *args], env=self.env, capture_output=True, text=True)

    def calls(self):
        return self.log.read_text() if self.log.exists() else ""

    def make_release(self, fail=False, bad_hash=False, link=False):
        stage = self.root / "release-source" / "updateself-2.2.0"
        shutil.copytree(self.source, stage)
        script = stage / "bin/updateself"
        script.write_text(script.read_text().replace("2.1.0", "2.2.0"))
        if fail:
            (stage / "install.sh").write_text('''#!/bin/bash
prefix=''
while [ "$#" -gt 0 ]; do case "$1" in --prefix) prefix=$2; shift 2;; *) shift;; esac; done
printf 'broken' > "$prefix/bin/updateself"
exit 42
''')
        if link:
            (stage / "escape").symlink_to("/etc/passwd")
        asset = self.release / "updateself-2.2.0.tar.gz"
        with tarfile.open(asset, "w:gz") as archive:
            archive.add(stage, arcname=stage.name)
        digest = "0" * 64 if bad_hash else hashlib.sha256(asset.read_bytes()).hexdigest()
        (self.release / "SHA256SUMS").write_text(f"{digest}  {asset.name}\n")

    def test_dry_runs_do_not_contact_network_create_locks_or_delete(self):
        before = sorted(p.name for p in self.temp.iterdir())
        for action in ["--uninstall", "--self-update", "--check-self-update"]:
            p = self.run_script(action, "--dry-run")
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertIn("Preview only", p.stdout)
        self.assertEqual(self.calls(), "")
        self.assertEqual(before, sorted(p.name for p in self.temp.iterdir()))
        self.assertTrue(self.exe.exists())

    def test_default_confirmation_required_and_mixed_options_refused(self):
        for args in [("--uninstall",), ("--uninstall", "--self-update"),
                     ("--uninstall", "--only", "brew"), ("--self-update", "--cleanup")]:
            p = self.run_script(*args)
            self.assertEqual(p.returncode, 2, (args, p.stdout, p.stderr))
            self.assertTrue(self.exe.exists())
        self.assertEqual(self.calls(), "")

    def test_uninstall_via_alias_survives_removing_running_executable(self):
        (self.prefix / "keep.txt").write_text("unrelated")
        p = self.run_script("--uninstall", "--yes", alias=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertFalse(self.exe.exists())
        self.assertFalse((self.prefix / "bin/updsf").is_symlink())
        self.assertEqual((self.prefix / "keep.txt").read_text(), "unrelated")
        self.assertEqual(list(self.temp.iterdir()), [])

    def test_modified_files_retained_with_manifest_and_nonzero_status(self):
        readme = self.prefix / "share/updateself/README.md"
        readme.write_text("user notes")
        p = self.run_script("--uninstall", "--yes")
        self.assertEqual(p.returncode, 1, p.stderr)
        self.assertEqual(readme.read_text(), "user notes")
        self.assertTrue((self.prefix / "share/updateself/manifest").exists())

    def test_parent_directory_symlink_refused(self):
        man = self.prefix / "share/man"
        man.rename(self.prefix / "saved-man")
        man.symlink_to(self.prefix / "saved-man", target_is_directory=True)
        p = self.run_script("--uninstall", "--yes")
        self.assertEqual(p.returncode, 2)
        self.assertTrue(self.exe.exists())
        self.assertIn("symlinked installation", p.stderr)

    def test_check_is_read_only_and_no_downgrade(self):
        self.env["TEST_LATEST"] = "2.0.0"
        original = self.exe.read_bytes()
        for action in ["--check-self-update", "--self-update"]:
            p = self.run_script(action, "--yes")
            self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(self.exe.read_bytes(), original)
        self.assertEqual(list(self.temp.iterdir()), [])
        self.assertNotIn("releases/download", self.calls())

    def test_verified_archive_update_preserves_prefix_and_shortcut(self):
        self.make_release()
        p = self.run_script("--self-update", "--yes")
        self.assertEqual(p.returncode, 0, (p.stdout, p.stderr))
        self.assertEqual(self.run_script("--version").stdout.strip(), "2.2.0")
        self.assertTrue((self.prefix / "bin/updsf").is_symlink())
        self.assertIn("attestation verify", self.calls())
        self.assertEqual(list(self.temp.iterdir()), [])

    def test_failed_installer_restores_binary_and_manifest(self):
        self.make_release(fail=True)
        original = self.exe.read_bytes()
        manifest = self.prefix / "share/updateself/manifest"
        previous = manifest.read_bytes()
        p = self.run_script("--self-update", "--yes")
        self.assertNotEqual(p.returncode, 0)
        self.assertEqual(self.exe.read_bytes(), original)
        self.assertEqual(manifest.read_bytes(), previous)
        self.assertIn("restoring", p.stderr)
        self.assertEqual(list(self.temp.iterdir()), [])

    def test_bad_checksum_and_bad_provenance_never_install(self):
        self.make_release(bad_hash=True)
        original = self.exe.read_bytes()
        p = self.run_script("--self-update", "--yes")
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("checksum mismatch", p.stderr)
        self.assertEqual(self.exe.read_bytes(), original)
        self.make_release_dir_cleanup()
        self.make_release()
        self.env["TEST_GH_FAIL"] = "1"
        p = self.run_script("--self-update", "--yes")
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("Provenance verification failed", p.stderr)
        self.assertEqual(self.exe.read_bytes(), original)

    def make_release_dir_cleanup(self):
        shutil.rmtree(self.root / "release-source")

    def test_archive_symlink_refused_before_extraction(self):
        self.make_release(link=True)
        p = self.run_script("--self-update", "--yes")
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("links/special files", p.stderr)
        self.assertEqual(self.run_script("--version").stdout.strip(), "2.1.0")

    def test_native_manager_delegation_and_ambiguous_ownership(self):
        self.stub("dpkg-query", 'printf "updateself: %s\\n" "$2"')
        self.stub("apt-get", 'echo "apt-get $*" >> "$TEST_CALLS"')
        p = self.run_script("--uninstall", "--yes")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("apt-get remove -y updateself", self.calls())
        self.stub("rpm", "echo updateself")
        self.stub("dnf", "exit 0")
        p = self.run_script("--uninstall", "--yes")
        self.assertEqual(p.returncode, 2)
        self.assertIn("Multiple installation owners", p.stderr)

    def test_macos_receipt_removal_uses_managed_manifest(self):
        self.env.update(TEST_OS="Darwin", TEST_MAC="1")
        manifest = self.prefix / "share/updateself/manifest"
        manifest.rename(manifest.with_name("package-manifest"))
        p = self.run_script("--uninstall", "--yes")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertFalse(self.exe.exists())
        self.assertIn("forget gr.makeasite.updateself", self.calls())

    def test_macos_update_refuses_modified_files_before_download(self):
        self.env.update(TEST_OS="Darwin", TEST_MAC="1")
        manifest = self.prefix / "share/updateself/manifest"
        manifest.rename(manifest.with_name("package-manifest"))
        readme = self.prefix / "share/updateself/README.md"
        readme.write_text("preserve these notes")
        p = self.run_script("--self-update", "--yes")
        self.assertEqual(p.returncode, 2)
        self.assertIn("Modified/unowned", p.stderr)
        self.assertEqual(readme.read_text(), "preserve these notes")
        self.assertNotIn("releases/download", self.calls())

    def test_brew_owner_uses_brew_and_refuses_root(self):
        cellar = self.root / "Cellar/updateself/2.1.0"
        (cellar / "bin").mkdir(parents=True)
        exe = cellar / "bin/updateself"
        exe.write_bytes(self.exe.read_bytes())
        self.env["TEST_CELLAR"] = str(cellar)
        self.env["TEST_UID"] = "1000"
        self.stub("brew", 'case "$1" in --prefix) echo "$TEST_CELLAR";; *) echo "brew $*" >> "$TEST_CALLS";; esac')
        p = subprocess.run([BASH, str(exe), "--uninstall", "--yes"], env=self.env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("brew uninstall updateself", self.calls())
        self.env["TEST_UID"] = "0"
        p = subprocess.run([BASH, str(exe), "--uninstall", "--yes"], env=self.env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 2)
        self.assertIn("account that owns", p.stderr)

    def test_nix_modern_profile_matches_exact_store_path(self):
        import json
        store = self.root / "nix/store/hash-updateself-2.1.0"
        (store / "bin").mkdir(parents=True)
        exe = store / "bin/.updateself-wrapped"
        exe.write_text(self.exe.read_text().replace("/nix/store/*/bin/*)", '"' + str(self.root / "nix/store") + '/"*/bin/*)'))
        self.env.update(TEST_UID="1000", TEST_PROFILE=json.dumps({"elements": {"updateself": {"storePaths": [str(store)]}}}))
        self.stub("nix", 'case "$*" in "profile list --json") echo "$TEST_PROFILE";; *) echo "nix $*" >> "$TEST_CALLS";; esac')
        self.stub("nix-env", "exit 1")
        # Python is used only for modern Nix profile JSON, not for other owners.
        self.stub("python3", 'exec "$TEST_PYTHON" "$@"')
        import sys
        self.env["TEST_PYTHON"] = sys.executable
        p = subprocess.run([BASH, str(exe), "--uninstall", "--yes"], env=self.env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("nix profile remove updateself", self.calls())
        self.env["TEST_PROFILE"] = json.dumps({"elements": {"other": {"storePaths": ["/nix/store/other"]}}})
        p = subprocess.run([BASH, str(exe), "--uninstall", "--yes"], env=self.env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 2)
        self.assertIn("ambiguous/declarative", p.stderr)

    def test_release_redirect_and_version_must_be_expected(self):
        for url in ["https://example.invalid/releases/tag/v2.2.0", "https://github.com/spaniakos/updateself/releases/tag/v2.2.0-rc1"]:
            self.stub("curl", "printf '%s' '" + url + "'")
            p = self.run_script("--check-self-update")
            self.assertEqual(p.returncode, 2)
            self.assertEqual(list(self.temp.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
