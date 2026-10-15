# updateself

Update installed operating-system packages and common CLI tools from one command.
Created by **G. Spanos**. Formerly `update-apt-system`; GPL-3.0-only.

`updateself` is the main command; **`updsf`** is its optional shortcut. The existing
repository name and `./update.sh` entry point remain compatible.

## Quick start

```bash
git clone https://github.com/spaniakos/update-apt-system.git
cd update-apt-system
bash update.sh --help
bash update.sh --dry-run

# Install for yourself; do not use sudo for --user.
bash install.sh --user
export PATH="$HOME/.local/bin:$PATH"
updateself --ask
updsf --only snap,flatpak
```

Requires Bash **3.2+** and standard Unix utilities. Bash must be installed first on
BSD/Alpine/minimal images. Normal execution uses your account and elevates native
package commands when necessary. Linux/BSD root execution supports system updates;
pass `--user alice` for that account's user tools.

**The default runs updates without script confirmations.** `--ask` confirms each
command; `--dry-run` prints the plan without running updaters. Authentication and
some vendor prompts can still occur. Native updates can restart services.

## What it updates

| Area | Backends/components |
| --- | --- |
| Linux native packages | APT, DNF5/DNF/YUM, Pacman, Zypper, APK, XBPS, Portage, Slackpkg |
| macOS | Homebrew, MacPorts, Apple Software Update, Mac App Store through `mas` |
| BSD | FreeBSD `pkg`, OpenBSD `pkg_add`, NetBSD `pkgin`; opt-in supported base patches |
| Cross-platform packages | Snap, Flatpak default/named system installations and target-user installation, Nix profiles |
| CLI tools | Rust, Composer, uv, pipx, Bun, Deno, Poetry, rclone, yt-dlp |
| Python | Discover PATH interpreters and pip; explicitly select environments for updates |
| Other | ClamAV signatures; optional npm globals, Cargo binaries and AUR |

Support means implemented command routing, not proof of live updates on every
host. See the [support and verification matrix](docs/SUPPORT.md).

Missing optional tools are skipped, never installed. Package-managed binaries
remain with their package manager. Standalone ownership must be positively
identified; uncertain installations are skipped. No project directories are
searched for dependency updates. No reboot is initiated.

## Examples

```bash
updateself --yes --cleanup
updateself --only system --full-upgrade  # APT only; may remove packages
updateself --skip rust,composer
updateself --include npm,cargo,aur
updateself --only python --venv "$HOME/venvs/cli"
updateself --only python --python "$HOME/.pyenv/versions/3.13.0/bin/python" --python-packages
updateself --only nix --base-install --nix-config home-manager --nix-flake "$HOME/config"
updateself --only apple --base-install  # ALL offered updates, possibly major macOS
updateself --log "$HOME/updateself.log"
```

For NixOS/nix-darwin system rebuilds the native rebuild command must be available
to the privileged command environment. Flake input changes require an additional
`--nix-update-inputs`; generations are never garbage-collected automatically.

`-n` retains its historical meaning **ask**, not dry-run. `-h`/`--help` and
`-v`/`--version` need no root privileges and return success.

## Installation, packages and development

- [Install, upgrade, uninstall and completions](docs/INSTALL.md)
- [Complete CLI reference](docs/CLI.md)
- [Platform support and limitations](docs/SUPPORT.md)
- [Troubleshooting and operational behaviour](docs/TROUBLESHOOTING.md)
- [Package builds and release process](docs/RELEASING.md)
- [Contributing and tests](CONTRIBUTING.md)
- [Security policy](SECURITY.md), [changelog](CHANGELOG.md), [roadmap](docs/ROADMAP.md)

GitHub Actions builds packages as downloadable artifacts. Version tags build a
draft GitHub Release after checks pass. **Nothing is submitted to distribution
repositories, registries, AUR, Homebrew or Nixpkgs.** Native package installation
must use the package manager; the Git installer refuses to overwrite its files.

```bash
make test       # Python 3 test runner; no updates to your host
make check      # Syntax, ShellCheck and workflow/schema checks where installed
bash scripts/package.sh portable
bash scripts/package.sh deb
```

Successful updater commands are labelled completed, not falsely counted as
changed packages. Upstream output distinguishes already-current tools from actual
updates. Any failed command causes exit 1 after independent components finish.
