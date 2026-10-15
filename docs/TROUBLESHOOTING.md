# Troubleshooting and operating notes

## Authentication and root

Start as your regular account. Only native privileged commands use sudo/doas.
With no terminal, elevation uses noninteractive mode and fails clearly instead
of waiting for a password. Vendor-specific prompts can still exist; --yes is not
a promise of fully unattended operation for every tool. Root native updates work
without sudo. User tools need a non-root --user/SUDO_USER and a switching mechanism.

The selected account's standard user-tool directories supplement PATH. No shell
startup files are sourced. Tools available only through shell functions/aliases
may not be detected. No arbitrary commands are evaluated from configuration.

## A command failed

Read its native output and the final failures list. Dependent operations are
skipped, independent components continue, and exit 1 is returned. Packages already
updated remain updated. The updater neither rolls back nor repairs package DBs.
Arch refresh and upgrade stay in one -Syu operation; resolve a failed transaction
before using other package commands. A declined prerequisite also skips its dependents.

## Locks

Runtime locks are atomic directories at `${TMPDIR:-/tmp}/updateself-UID.lock`, one
per invoking UID. Native package-manager locks coordinate system transactions
across accounts. Do not remove those locks. If updateself exits normally or receives
INT/TERM, its directory is removed. After SIGKILL/crash, inspect running processes
and remove only the stale updateself directory once no invocation owns it.

## Logs and dry-run

--log appends all output to a regular file instead of the terminal. It never logs
password input. Use a private path. Symlink logs are rejected. Dry-run and --log
are intentionally incompatible; capture dry-run output with shell redirection if
you deliberately want a file. Logs contain paths/usernames and updater output.

## Python and global packages

Discovery reports interpreters on PATH, pip versions, virtualenv state and the
externally-managed marker. No missing pip is bootstrapped. An explicit --venv or
--python is required to update pip; --python-packages additionally upgrades that
environment's package list. This can change major versions and does not honour
unprovided project constraints. Prefer project dependency workflows for projects.
Never bypass externally-managed protection to fix a skipped system pip.

## Skipped self-updater

A command existing is not sufficient proof it owns its executable. Homebrew,
native packages, Nix, pipx and uv tools must update through their owner. Unknown
installation layouts are skipped. Report a supported manual layout upstream with
its installation method and executable path; do not use sudo to force a self-update.

## Package trust / installed command conflicts

Download only reviewed releases and verify checksums. Packaging does not imply
distribution endorsement. Native package managers reject owned-file conflicts;
the Git installer refuses to replace an unrelated updateself or updsf. Do not mix
native package and Git installation at the same prefix. Uninstall the old method first.

## Restart and configuration notices

No reboot is initiated. Linux /var/run/reboot-required is reported when present;
otherwise inspect backend output. Apple/BSD updates may require restart. Slackware
.new files need manual configuration review. Native package hooks may restart
services. Cleanup is deliberately conservative and backend-specific.
