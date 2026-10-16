"""Exercise command routing without invoking any real package manager."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="updateself-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls"
        self.osrelease = self.root / "os-release"
        self.osrelease.write_text('ID=debian\n')
        # Instrument paths and effective UID only in the test copy. Production
        # has no environment switch allowing platform/privilege checks to be bypassed.
        source = (ROOT / "bin/updateself").read_text()
        source = source.replace('/etc/os-release', str(self.osrelease))
        source = source.replace('"$EUID"', '"${TEST_UID:-1000}"')
        source = source.replace('updateself-$EUID.lock', 'updateself-${TEST_UID:-1000}.lock')
        source = source.replace('/usr/sbin/softwareupdate', str(self.bin / 'softwareupdate'))
        source = source.replace('/etc/flatpak/installations.d', str(self.root / 'flatpak'))
        self.subject = self.root / "subject"
        self.subject.write_text(source)
        self.env = dict(os.environ, HOME=str(self.root), TMPDIR=str(self.root),
                        PATH=str(self.bin) + ":/usr/bin:/bin", TEST_LOG=str(self.log),
                        TEST_OS="Linux", TEST_UID="1000", TEST_CURRENT="tester")
        self.env.pop("SUDO_USER", None)
        self.stub("uname", 'case "$1" in -s) echo "$TEST_OS";; -m) echo x86_64;; -i) echo GENERIC;; *) echo 14.3;; esac')
        self.stub("id", 'case "$1" in -un) echo "$TEST_CURRENT";; *) exit 0;; esac')
        self.stub("getent", 'printf "tester:x:1000:1000::%s:/bin/bash\\n" "$HOME"')
        self.stub("sudo", 'while [ "$#" -gt 0 ]; do case "$1" in -n|-H|--) shift;; -u) shift 2;; *) break;; esac; done; exec "$@"')
        self.stub("dpkg-query", 'exit 1')
        self.stub("rpm", 'exit 1')
        self.stub("pgrep", 'exit 1')

    def stub(self, name, body=None):
        if body is None:
            body = '''
case "$*" in *'--version'*|*'profile list'*) exit 0;; esac
if [ "${0##*/}" = pkg ] && [ "$1" = info ]; then
    [ "${TEST_PKGBASE:-0}" = 1 ]; exit $?
fi
printf '%s' "${0##*/}" >> "$TEST_LOG"
printf ' %s' "$@" >> "$TEST_LOG"
printf '\\n' >> "$TEST_LOG"
if [ "${0##*/} $*" = "${TEST_FAIL:-}" ]; then exit 42; fi
'''
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)
        return path

    def run_script(self, *args):
        p = subprocess.run([os.environ.get("BASH_BIN", "bash"), str(self.subject), *args], env=self.env,
                           capture_output=True, text=True)
        calls = self.log.read_text().splitlines() if self.log.exists() else []
        return p, calls

    def test_help_version_validation(self):
        for opt in ["-h", "--help", "-v", "--version", "--list-components"]:
            p, c = self.run_script(opt)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(c, [])
        for args in [("--unknown",), ("--user",), ("--only", "wat"),
                     ("--only", "system,,python"), ("--ask",),
                     ("--python-packages",), ("--nix-config", "nixos"),
                     ("--python", "relative/path")]:
            p, c = self.run_script(*args)
            self.assertEqual(p.returncode, 2, (args, p.stdout, p.stderr))
            self.assertEqual(c, [])

    def test_native_routing(self):
        cases = [
            ("debian", "apt-get", "apt-get upgrade -y"),
            ("fedora", "dnf5", "dnf5 upgrade --refresh -y"),
            ("arch", "pacman", "pacman -Syu --noconfirm"),
            ("opensuse-tumbleweed", "zypper", "zypper --non-interactive dup"),
            ("opensuse-leap", "zypper", "zypper --non-interactive update"),
            ("alpine", "apk", "apk upgrade"),
            ("void", "xbps-install", "xbps-install -Su -y"),
            ("gentoo", "emerge", "emerge --update --deep --newuse @world"),
            ("slackware", "slackpkg", "slackpkg -batch=on -default_answer=y upgrade-all"),
        ]
        for distro, cmd, expected in cases:
            with self.subTest(distro=distro):
                self.log.unlink(missing_ok=True)
                self.osrelease.write_text(f'ID="{distro}"\n')
                self.stub(cmd)
                p, c = self.run_script("--only", "system")
                self.assertEqual(p.returncode, 0, (p.stdout, p.stderr))
                self.assertIn(expected, c)

    def test_bsd_and_mac_routing(self):
        for osname, cmd, expected in [("FreeBSD", "pkg", "pkg upgrade -y"),
                                      ("OpenBSD", "pkg_add", "pkg_add -u -I"),
                                      ("NetBSD", "pkgin", "pkgin -y upgrade"),
                                      ("Darwin", "softwareupdate", "softwareupdate --list")]:
            with self.subTest(os=osname):
                self.log.unlink(missing_ok=True)
                self.env["TEST_OS"] = osname
                self.stub(cmd)
                p, c = self.run_script("--only", "system,apple")
                self.assertEqual(p.returncode, 0, p.stderr)
                self.assertIn(expected, c)
                self.assertFalse(any("--install" in x for x in c))

    def test_failure_gates_cleanup_but_continues_independent(self):
        self.stub("apt-get"); self.stub("snap")
        self.env["TEST_FAIL"] = "apt-get -o APT::Update::Error-Mode=any update"
        p, c = self.run_script("--only", "system,snap", "--cleanup")
        self.assertEqual(p.returncode, 1)
        self.assertIn("snap refresh", c)
        self.assertFalse(any("upgrade" in x or "autoremove" in x for x in c))

    def test_dry_run_never_calls_mutating_commands_or_creates_lock(self):
        for cmd in ["apt-get", "snap", "flatpak", "brew", "pipx", "uv"]:
            self.stub(cmd)
        p, c = self.run_script("--only", "system,snap,flatpak,brew,pipx,uv", "--dry-run", "--cleanup")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(c, [])
        self.assertFalse(list(self.root.glob("*.lock")))

    def test_skip_precedence_and_full_upgrade(self):
        self.stub("apt-get"); self.stub("snap")
        p, c = self.run_script("--only", "system,snap", "--skip", "snap", "--full-upgrade")
        self.assertEqual(p.returncode, 0)
        self.assertIn("apt-get dist-upgrade -y", c)
        self.assertNotIn("snap refresh", c)

    def test_lock_and_signal_cleanup_contract(self):
        lock = self.root / "updateself-1000.lock"; lock.mkdir()
        p, _ = self.run_script("--only", "snap")
        self.assertEqual(p.returncode, 75)
        self.assertTrue(lock.exists())

    def test_brew_dependency_failure(self):
        self.stub("brew"); self.env["TEST_FAIL"] = "brew update"
        p, c = self.run_script("--only", "brew", "--cleanup")
        self.assertEqual(p.returncode, 1)
        self.assertEqual(c, ["brew update"])

    def test_root_does_not_update_user_tools(self):
        self.env.update(TEST_CURRENT="root", TEST_UID="0")
        for cmd in ["rustup", "pipx", "bun"]: self.stub(cmd)
        p, c = self.run_script("--only", "rust,pipx,bun,python")
        self.assertEqual(p.returncode, 0)
        self.assertEqual(c, [])

    def test_unknown_native_os_fails(self):
        self.env["TEST_OS"] = "UnknownOS"
        p, _ = self.run_script("--only", "system")
        self.assertEqual(p.returncode, 1)

    def fake_python(self):
        return self.stub('python3', '''
case "$*" in
  *sysconfig*) printf '%s\\n' "$0" '3.13.0' "${TEST_MARKER:-0}" "${TEST_VENV:-0}" ;;
  *'pip --version'*) echo 'pip 25.0 (python 3.13)' ;;
  *'pip install'*) printf 'python3 %s\\n' "$*" >> "$TEST_LOG" ;;
  *) exit 1 ;;
esac
''')

    def test_python_discovery_is_read_only(self):
        self.fake_python()
        p, c = self.run_script('--only', 'python')
        self.assertEqual(p.returncode, 0, (p.stdout, p.stderr))
        self.assertIn('[PYTHON]', p.stdout)
        self.assertEqual(c, [])

    def test_explicit_python_pip_update_and_externally_managed_guard(self):
        py = self.fake_python()
        p, c = self.run_script('--only', 'python', '--python', str(py))
        self.assertEqual(p.returncode, 0, (p.stdout, p.stderr))
        self.assertIn('python3 -I -m pip install --upgrade pip', c)
        self.log.unlink()
        self.env['TEST_MARKER'] = '1'
        p, c = self.run_script('--only', 'python', '--python', str(py))
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(c, [])

    def test_venv_pip_allowed_even_when_base_has_marker(self):
        py = self.fake_python()
        self.env.update(TEST_MARKER='1', TEST_VENV='1')
        p, c = self.run_script('--only', 'python', '--python', str(py), '--dry-run')
        self.assertEqual(p.returncode, 0, (p.stdout, p.stderr))
        self.assertIn('pip install --upgrade pip', p.stdout)
        self.assertEqual(c, [])

    def test_named_flatpak_installation(self):
        self.stub('flatpak')
        (self.root / 'flatpak').mkdir()
        (self.root / 'flatpak/extra.conf').write_text('[Installation "extra"]\nPath=/opt/flatpak\n')
        p, c = self.run_script('--only', 'flatpak')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('flatpak update --system -y', c)
        self.assertIn('flatpak update --installation=extra -y', c)
        self.assertIn('flatpak update --user -y', c)

    def test_unrecognised_selfupdater_is_not_executed(self):
        self.stub('bun')
        p, c = self.run_script('--only', 'bun')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(c, [])
        self.assertIn('ownership uncertain', p.stdout)

    def test_user_owned_bun_is_updated(self):
        (self.root / '.bun/bin').mkdir(parents=True)
        bun = self.root / '.bun/bin/bun'
        p = self.stub('bun')
        shutil.move(p, bun)
        p, c = self.run_script('--only', 'bun')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(c, ['bun upgrade'])

    def test_dry_run_log_rejected_before_write(self):
        logfile = self.root / 'dry.log'
        p, _ = self.run_script('--dry-run', '--log', str(logfile))
        self.assertEqual(p.returncode, 2)
        self.assertFalse(logfile.exists())

    def test_symlinked_home_still_recognises_user_tool(self):
        real = self.root / '.bun/bin'
        real.mkdir(parents=True)
        shutil.move(self.stub('bun'), real / 'bun')
        alias = self.root / 'home-link'
        alias.symlink_to(self.root, target_is_directory=True)
        self.env['HOME'] = str(alias)
        p, c = self.run_script('--only', 'bun')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(c, ['bun upgrade'])

    def test_freebsd_pkgbase_requires_explicit_base_opt_in(self):
        self.env.update(TEST_OS='FreeBSD', TEST_PKGBASE='1')
        self.stub('pkg')
        p, c = self.run_script('--only', 'system')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(c, [])
        p, c = self.run_script('--only', 'system', '--base-install')
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('pkg upgrade -y', c)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="updateself install ")
        self.addCleanup(self.tmp.cleanup)
        self.stage = Path(self.tmp.name)
        self.base = self.stage / "usr/local"

    def install(self, *args):
        return subprocess.run([os.environ.get("BASH_BIN", "bash"), str(ROOT / "install.sh"), "--system", "--prefix", "/usr/local",
                               "--destdir", str(self.stage), *args], capture_output=True, text=True)

    def test_install_upgrade_commands_and_remove(self):
        for _ in range(2):
            p = self.install(); self.assertEqual(p.returncode, 0, p.stderr)
        for cmd in ["updateself", "updsf"]:
            p = subprocess.run([str(self.base / "bin" / cmd), "--version"], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(p.stdout.strip(), (ROOT / "VERSION").read_text().strip())
        p = self.install("--uninstall"); self.assertEqual(p.returncode, 0, p.stderr)
        self.assertFalse((self.base / "bin/updateself").exists())
        self.assertFalse((self.base / "bin/updsf").is_symlink())

    def test_alias_conflict_preserved(self):
        (self.base / "bin").mkdir(parents=True)
        (self.base / "bin/updsf").write_text("other tool")
        self.assertEqual(self.install().returncode, 0)
        self.assertEqual((self.base / "bin/updsf").read_text(), "other tool")
        self.install("--uninstall")
        self.assertEqual((self.base / "bin/updsf").read_text(), "other tool")

    def test_modified_main_refused_and_retained(self):
        self.assertEqual(self.install().returncode, 0)
        main = self.base / "bin/updateself"
        main.write_text("modified")
        self.assertNotEqual(self.install().returncode, 0)
        self.install("--uninstall")
        self.assertEqual(main.read_text(), "modified")

    def test_bsd_manual_directory(self):
        shim = self.stage / 'shims'
        shim.mkdir()
        uname = shim / 'uname'
        uname.write_text('#!/bin/sh\necho OpenBSD\n')
        uname.chmod(0o755)
        env = dict(os.environ, PATH=str(shim) + ':' + os.environ['PATH'])
        cmd = [os.environ.get('BASH_BIN', 'bash'), str(ROOT / 'install.sh'),
               '--system', '--prefix', '/usr/local', '--destdir', str(self.stage)]
        p = subprocess.run(cmd, env=env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertTrue((self.base / 'man/man1/updateself.1').is_file())
        p = subprocess.run(cmd + ['--uninstall'], env=env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertFalse((self.base / 'man/man1/updateself.1').exists())


if __name__ == "__main__":
    unittest.main()
