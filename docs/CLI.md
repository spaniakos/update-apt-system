# CLI reference (2.1.0)

## Self-management (separate from system/tool updates)

- **--check-self-update**: read-only latest stable release check.
- **--self-update**: update through the detected installation owner.
- **--uninstall**: remove updateself through that owner.
- Combine with **--dry-run** for an offline preview or **--yes** for reviewed automation.
  Self-update/removal ask by default and cannot be combined with component options.

See [self-management](wiki/Self-Management.md) for verification, dependencies,
modified-file retention, configured-repository limitations and recovery.

`updateself`, `updsf` and the checkout's `bash update.sh` accept the same options.
Long options use separate arguments (`--user alice`), not `--user=alice`.
Short options are separate (`-y -u alice`), not grouped.

| Option | Meaning |
| --- | --- |
| `-h`, `--help` | Complete built-in help; exit 0 |
| `-v`, `--version` | Version; exit 0 |
| `-y`, `--yes` | Skip script and supported updater confirmations; default |
| `-n`, `--ask` | Confirm update commands; terminal required |
| `-u`, `--user USER` | Account for user tools; invoking user or SUDO_USER by default |
| `--dry-run` | Print planned commands; no updaters, locks or log writes |
| `--only LIST` | Only these comma-separated components; enables selected optional components |
| `--skip LIST` | Exclude components; takes precedence over only/include |
| `--include LIST` | Add optional components to default selection |
| `--cleanup` | Backend-specific cleanup, gated on successful preceding updates |
| `--full-upgrade` | APT dist-upgrade instead of upgrade; no distro-release migration |
| `--base-install`, `--apple-install` | Install Apple/BSD base updates; enable explicitly selected Nix rebuild |
| `--greedy` | Homebrew latest/self-updating casks |
| `--python PATH` | Explicit interpreter, repeatable; use an absolute executable path |
| `--venv PATH` | Explicit venv directory, repeatable |
| `--python-packages` | Also upgrade pip-listed packages in explicit environments; may cross major versions |
| `--nix-config KIND` | nixos, home-manager or darwin; requires base-install |
| `--nix-flake PATH` | Local flake directory; requires nix-config |
| `--nix-update-inputs` | Update that configuration's lock file; requires both options above |
| `--log FILE` | Append output to a regular file instead of the terminal; incompatible with dry-run |
| `--no-color` | Accepted; output is always plain |
| `--list-components` | Print valid identifiers |

Default components: `system,brew,macports,apple,mas,snap,flatpak,rust,composer,clamav,uv,pipx,python,bun,deno,poetry,rclone,yt-dlp,nix`.
Optional: `npm,cargo,aur`. Components not applicable to the host do nothing.
Repeated only/skip/include options replace the previous list; they do not append.

`--only system` means the native Linux/BSD backend; on macOS choose `apple`, `brew`
or `macports`. `--only python` performs discovery; pip changes require explicit
interpreters. Python discovery is read-only even in normal mode until selected.

User-level operations never target all accounts. Use separate runs for distinct
users. Self-update detection deliberately skips unknown/manual system-wide
installations rather than inferring ownership from a command name.

Dry-run does not contact upstream to discover available versions. It may perform
read-only interpreter, package-owner, Nix-profile and installation discovery.
It cannot predict whether the following actual transaction will succeed.

Exit codes: 0 completed/skipped/preview; 1 update failure; 2 invalid arguments or
environment; 75 existing lock; 130 SIGINT; 143 SIGTERM. No rollback is attempted.
