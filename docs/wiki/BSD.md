# BSD

Install Bash first if absent, using your usual administrative access:

| Platform | Bash prerequisite | Application updates |
| --- | --- | --- |
| FreeBSD | pkg install bash | pkg upgrade |
| OpenBSD | pkg_add bash | pkg_add -u |
| NetBSD with configured pkgin | pkgin install bash | pkgin refresh/upgrade |

```bash
updateself --only system --dry-run
updateself --only system --ask
updateself --only system --base-install --ask
```

Native commands can use root, sudo or doas. Switching from root to another user
requires sudo/runuser; user tools need a non-root target account.

## Base patches

- Traditional FreeBSD: supported freebsd-update fetch/install; jails and
  non-GENERIC kernels are skipped for this path.
- FreeBSD pkgbase: the combined pkg transaction can update the OS, so it requires
  --base-install; without it the combined transaction is skipped.
- OpenBSD: supported syspatch binary base patches require --base-install.
- NetBSD: base OS upgrades are outside the implemented scope.

No release migration or reboot is initiated. Inspect native output for restart
requirements. CI verifies native package installation/removal, not live base
patching on every release/custom kernel.

OpenBSD archives must retain updateself-VERSION.tgz before installation.
Manuals use PREFIX/man/man1 on OpenBSD/NetBSD and PREFIX/share/man/man1 on
FreeBSD. See [[Installation]], [[Packages and Releases|Packages-and-Releases]]
and [[Platform Support|Platform-Support]].
