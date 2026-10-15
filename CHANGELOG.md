# Changelog

## 2.0.0 — unreleased

- Rename the application to updateself, with optional updsf command.
- Add macOS, major Linux package families, Nix and three BSD package backends.
- Add installed-tool updates, ownership checks and explicit Python environments.
- Implement reliable options, dry-run, user separation, failure summary and locks.
- Add Git/archive installation, removal, manual and shell completions.
- Add generated GitHub Wiki pages, navigation and default-branch publication.
- Add automated tests, CI, native package generation and draft release workflow.
- Preserve GPL licence, original authorship, repository URL and update.sh entry point.

Migration: -n still asks, -y is consistently the default. Cleanup and APT
dist-upgrade now require explicit options. Run without sudo normally. Help/version
return 0. Root no longer defaults user-level tools to root. See docs/CLI.md.

## 1.1.x

Original APT updater with Flatpak, Snap, Rust, Composer and ClamAV support.
