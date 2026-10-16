# updateself

Update installed system packages and common CLI tools with **updateself**, or its
short command **updsf**. Supports macOS, major Linux package-manager families,
FreeBSD, OpenBSD, NetBSD and Nix. Created by **G. Spanos**, licensed under GPLv3.

## Downloads

**[Download published releases](https://github.com/spaniakos/updateself/releases)**
for installers, archives, checksums and release notes. Downloads appear when a
release is published; merging alone does not publish a release. Development builds
are available under **Actions → CI → Artifacts** and require GitHub sign-in.
GitHub Packages and distribution repositories are separate future publication targets.

## Get started

```bash
git clone https://github.com/spaniakos/updateself.git
cd update-apt-system
bash update.sh --dry-run
bash install.sh --user
export PATH="$HOME/.local/bin:$PATH"
updateself --ask
```

Requires Bash 3.2+; install Bash first on BSD and minimal Linux. Run as your normal
account; privileged commands request elevation. The default skips update
confirmations: use **--ask** to review commands or **--dry-run** to preview them.
Missing optional tools are skipped, never installed automatically.

## Documentation — GitHub Wiki

For updateself's own installation (2.1.0+): `updateself --check-self-update`,
`updateself --self-update` and `updateself --uninstall`. The mutation commands ask
for confirmation by default; inspect `--dry-run` first. See
[self-management](docs/wiki/Self-Management.md) for ownership and update-source limits.

**[Open the Wiki](https://github.com/spaniakos/updateself/wiki)** for full
documentation, platform guides and troubleshooting.

| Start here | Reference and help |
| --- | --- |
| [Installation](https://github.com/spaniakos/updateself/wiki/Installation) | [Command reference](https://github.com/spaniakos/updateself/wiki/Command-Reference) |
| [macOS](https://github.com/spaniakos/updateself/wiki/macOS) | [Supported tools](https://github.com/spaniakos/updateself/wiki/Supported-Tools) |
| [Linux](https://github.com/spaniakos/updateself/wiki/Linux) | [Python and pip](https://github.com/spaniakos/updateself/wiki/Python-and-pip) |
| [BSD](https://github.com/spaniakos/updateself/wiki/BSD) | [Nix](https://github.com/spaniakos/updateself/wiki/Nix) |
| [Packages and releases](https://github.com/spaniakos/updateself/wiki/Packages-and-Releases) | [Troubleshooting](https://github.com/spaniakos/updateself/wiki/Troubleshooting) |

The Wiki is generated from reviewed sources in this repository. Release archives
retain their matching docs. See [documentation maintenance](docs/WIKI.md).
The same references are also available in [docs](docs).

## Contributing and releases

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md),
[CHANGELOG.md](CHANGELOG.md) and [LICENSE](LICENSE).

CI builds downloadable packages and verifies installation/removal. Version tags
prepare **draft GitHub Releases**. Distribution-repository submissions remain
[future work](docs/ROADMAP.md). The existing update.sh entry point is retained.
