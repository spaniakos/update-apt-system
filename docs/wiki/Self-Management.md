# Updating and uninstalling updateself

Available starting with **2.1.0**. A 2.0.0 installation must first be upgraded
with the Git/archive installer or matching native package. Normal system/tool
updates never replace or uninstall updateself itself.

```bash
updateself --check-self-update
updateself --self-update --dry-run
updateself --self-update
updateself --uninstall --dry-run
updateself --uninstall
```

Self-update and uninstall ask once before changing anything, even though normal
update runs default to --yes. For reviewed automation, append **--yes**. Without
a terminal, mutation commands require --yes. Authentication and package-manager
dependency prompts can still occur. --check-self-update performs a read-only
GitHub request and requires no confirmation.

Use only one self-management action at a time. It can be combined with --dry-run,
--yes/--ask and --no-color. Component selection, --user, cleanup, Python/Nix
configuration and --log apply to normal updates and cannot be mixed into this mode.

## Ownership and update sources

| Installation owner | Update | Uninstall |
| --- | --- | --- |
| Git/archive install.sh | Verified stable GitHub archive, same prefix | Ownership manifest; preserve modified/unrelated files |
| macOS pkg | Verified matching Intel/Apple Silicon release pkg, native Installer | Managed file manifest; forget receipt after removal |
| Debian, RPM, Arch, Alpine, Void, Gentoo, Slackware | Target updateself through its native manager | Native package removal; no automatic dependency cleanup |
| FreeBSD, OpenBSD, NetBSD | Native manager and configured repository | Native package removal |
| Homebrew / MacPorts | Upgrade updateself through that manager | Uninstall updateself through that manager |
| Imperative Nix profile / nix-env | Upgrade the exact identified profile entry | Remove that entry |
| Declarative Nix configuration | Refused; edit the owning configuration and rebuild | Refused; remove from the configuration and rebuild |
| Unknown owner / source checkout | Refused; use the original installer | Refused; no path guessing |

Native managers use their **configured package sources**. This project has not
submitted packages to distribution repositories. If your locally installed package
has no updateself repository/channel, manually download the next matching GitHub
release package and install it through the native manager. A successful manager
command does not promise that its channel contains the latest GitHub release.
Refresh system metadata through the normal updater first where appropriate.
Arch self-update does not refresh databases or perform a system-wide upgrade.

Modern Nix profile detection needs Python 3 to parse profile JSON and requires
exactly one matching store path. Legacy nix-env uses its exact installed name.
Run user-manager operations as their owning account, not through sudo. System
operations request sudo/doas only when needed.

## Download verification

Checking/updating requires curl with HTTPS support. Archive/pkg downloads are
limited to the project's latest stable GitHub release, are checked against its
SHA256SUMS using sha256sum or shasum, and reject malformed versions/checksums.
Downgrades, prerelease redirects and same-version reinstalls are not performed.
No dependencies are installed automatically.

If GitHub CLI is installed, provenance verification is also required to pass.
Otherwise the command explicitly reports that only the HTTPS release checksum
was verified. Checksums from the same release provide integrity, not independent
publisher authentication or platform code signing. macOS installers remain unsigned
and not notarized. GitHub rate limits, network failures and verification failures
stop installation.

## Uninstall and recovery

The command copies its lifecycle functions into a private temporary helper before
removing/replacing the running executable. It leaves shared directories and user
logs in place. Git/archive and macOS pkg removal use a fixed list of managed paths;
modified files, symlinked installation directories and ambiguous ownership are
never silently removed. Native package managers apply their own file/configuration
retention rules.

For macOS pkg installs, the receipt is forgotten only after all managed files were
removed. If modified files remain, the receipt and package-manifest remain and the
command exits nonzero. pkgutil --forget alone does not uninstall files.

Git/archive and macOS pkg self-update refuse modified managed files. After a failed Git/archive installer
or version check it restores the previous managed files and manifest. If interrupted
or rollback fails, the private recovery directory remains under TMPDIR (normally
/tmp); it contains backup/ and the previous manifest. Stop, inspect those files and
restore them to the original prefix before removing the stale updateself-UID.lock.
Logs and empty shared directories are retained. Recovery is not guaranteed after
power loss. Native package transactions and macOS Installer use their own recovery
mechanisms; no automatic cross-manager rollback is promised.

The original checkout/archive **install.sh --uninstall**, with the same prefix and
mode used at installation, remains available for Git/archive installs.
