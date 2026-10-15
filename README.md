# updateself

Update installed system packages and common CLI tools with **updateself**, or its
short command **updsf**. Supports macOS, major Linux package-manager families,
FreeBSD, OpenBSD, NetBSD and Nix. Created by **G. Spanos**, licensed under GPLv3.

## Downloads

**[Download published releases](https://github.com/spaniakos/update-apt-system/releases)**
for installers, archives, checksums and release notes. The first 2.0.0 release is
being prepared; downloads appear after its draft is published. Development builds
are available under **Actions → CI → Artifacts** and require GitHub sign-in.
GitHub Packages and distribution repositories are separate future publication targets.

## Get started

```bash
git clone https://github.com/spaniakos/update-apt-system.git
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

**[Open the Wiki](https://github.com/spaniakos/update-apt-system/wiki)** for full
documentation, platform guides and troubleshooting.

| Start here | Reference and help |
| --- | --- |
| [Installation](https://github.com/spaniakos/update-apt-system/wiki/Installation) | [Command reference](https://github.com/spaniakos/update-apt-system/wiki/Command-Reference) |
| [macOS](https://github.com/spaniakos/update-apt-system/wiki/macOS) | [Supported tools](https://github.com/spaniakos/update-apt-system/wiki/Supported-Tools) |
| [Linux](https://github.com/spaniakos/update-apt-system/wiki/Linux) | [Python and pip](https://github.com/spaniakos/update-apt-system/wiki/Python-and-pip) |
| [BSD](https://github.com/spaniakos/update-apt-system/wiki/BSD) | [Nix](https://github.com/spaniakos/update-apt-system/wiki/Nix) |
| [Packages and releases](https://github.com/spaniakos/update-apt-system/wiki/Packages-and-Releases) | [Troubleshooting](https://github.com/spaniakos/update-apt-system/wiki/Troubleshooting) |

The Wiki is generated from reviewed sources in this repository. Release archives
retain their matching docs. See [documentation maintenance](docs/WIKI.md).
The same references are also available in [docs](docs).

## Contributing and releases

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md),
[CHANGELOG.md](CHANGELOG.md) and [LICENSE](LICENSE).

CI builds downloadable packages and verifies installation/removal. Version tags
prepare **draft GitHub Releases**. Distribution-repository submissions remain
[future work](docs/ROADMAP.md). The existing update.sh entry point is retained.
