# Platform support and verification

All rows below have implemented routing and automated mocked tests where noted.
A green package job validates that artifact on its build OS; it does not certify
every update on arbitrary production systems. Consult the actual workflow run.

| Family | Procedure | CI environment |
| --- | --- | --- |
| Debian/Ubuntu and derivatives | apt-get update then upgrade; optional dist-upgrade | Debian package build/install; Linux mocked routing |
| Fedora/RHEL/Rocky/Alma/CentOS Stream | DNF5, DNF, then YUM fallback | Fedora RPM build/install; mocked routing |
| Arch/Manjaro/EndeavourOS | pacman -Syu; no partial refresh | Arch package build/install; mocked routing |
| openSUSE Leap/SLES | zypper refresh/update | RPM format plus mocked routing; live SUSE transactions unverified |
| openSUSE Tumbleweed | zypper refresh/dup | Mocked routing; live transactions unverified |
| Alpine | apk update/upgrade | Alpine package build/install; mocked routing |
| Void | xbps-install -Su twice (XBPS bootstrap transaction) | Void package build/install; mocked routing |
| Gentoo | emerge --sync; world; preserved-rebuild | Ebuild generated; source builds not run in CI |
| Slackware | slackpkg update/install-new/upgrade-all | Slackware package build/install; mocked routing |
| macOS Intel/Apple Silicon | Brew, MacPorts, softwareupdate, mas | Hosted macOS tests/pkg build; live Apple/App Store updates not run |
| NixOS | Explicit nixos-rebuild switch | Nix build verification and mocked routing; activation not run |
| FreeBSD | pkg; opt-in freebsd-update or installed pkgbase | VM package build/install; base update not run |
| OpenBSD | pkg_add -u; opt-in syspatch | VM package build/install; base patching not run |
| NetBSD | pkgin | VM package build/install; base OS upgrades excluded |

## Important boundaries

- Immutable/transactional/bootc/OSTree hosts: native update is reported unsupported;
  user/application components can still run. Their system update strategy is future work.
- Derivatives inherit their configured repositories and restrictions; no repository,
  mirror, pin, hold, release branch or trust-key changes are made.
- BSD and minimal Linux require Bash installed first. sudo, doas or root provides
  native administrative access. Switching from root to another user needs sudo/runuser.
- FreeBSD base updates skip jails and non-GENERIC kernels. No base-package migration.
- Nix profile CLI capability is checked at runtime. Locked flake references remain
  pinned; legacy nix-env uses the selected user's configured channels. No daemon
  self-upgrade, channel switching or generation deletion.
- Deno prerelease installations are skipped. Detected LTS uses its channel command;
  channel reporting varies by Deno release, so review previews for pinned runtimes.
- System Python/pip are left to their distributor. Explicit non-venv Python must
  live in the target user's home and not in known managed layouts. Conda environment
  updates and pyenv interpreter installation are not automated.
- The first release does not scan every Python or every user environment on disk.
- FreshClam skips an active daemon; it never stops services or removes locks.
- Cargo requires an existing cargo-update helper; AUR requires yay/paru. npm only
  updates the active user-owned prefix within installed semver constraints.
- Standalone self-updaters currently recognise supported user-owned layouts only.
  A manually installed /usr/local/bin tool can be skipped until its ownership is
  configured deliberately in a future release.

## Upstream behaviour references

- [Arch maintenance](https://wiki.archlinux.org/title/System_maintenance)
- [DNF5 upgrade](https://dnf5.readthedocs.io/en/latest/commands/upgrade.8.html)
- [Tumbleweed upgrades](https://doc.opensuse.org/documentation/tumbleweed/updating_upgrading_reverting/)
- [Externally managed Python](https://packaging.python.org/en/latest/specifications/externally-managed-environments/)
- [Nix manual](https://nix.dev/manual/nix/stable/)
- [FreeBSD updates](https://docs.freebsd.org/en/books/handbook/cutting-edge/)
- [OpenBSD packages](https://www.openbsd.org/faq/faq15.html)
- [NetBSD packages](https://www.netbsd.org/docs/pkgsrc/using.html)
