# Roadmap

## Current release work

Cross-platform runtime, documented Git install/uninstall, both command names,
tests, CI, native package builds, checksums and draft GitHub Release artifacts.
No distribution submission or repository hosting in this phase.

## Future distribution work

- Debian/Ubuntu submission or signed APT repository.
- Fedora/RHEL/openSUSE submission or signed RPM repository.
- Arch/AUR, Alpine, Void, Gentoo and Slackware distribution integration.
- Homebrew/MacPorts submissions, Nixpkgs and binary-cache integration.
- FreeBSD Ports, OpenBSD ports and NetBSD pkgsrc submissions.
- Persistent package signing, macOS Developer ID signing/notarization.
- Optional package-name aliases only where repository policy permits.

## Future runtime work

- Immutable/transactional/bootc systems with dedicated update backends.
- Explicit policy/configuration for additional standalone system-wide binaries.
- Conda/mamba, interpreter managers and additional package ecosystems.
- Configuration-aware runtime channels/version constraints.
- Better structured changed/current status where upstream output is machine-readable.
- Additional BSD variants and live update test environments.

Repository renaming and automatic scheduling are separate future decisions.
