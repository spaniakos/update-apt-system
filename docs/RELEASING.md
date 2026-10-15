# CI, packages and releases

## Triggers

- Pull requests and branch pushes: syntax, ShellCheck, unit/installer tests,
  package generation and disposable installation/removal checks.
- Manual workflow dispatch: the same build matrix, downloadable workflow artifacts.
- `vX.Y.Z` tag: require VERSION/runtime/man consistency, run checks/builds, collect
  artifacts, checksums and provenance, then create a **draft GitHub Release**.
  Review the build report and publish the draft manually. No registry submission.

Builds have no package-repository publishing credentials. GITHUB_TOKEN only gets
release/attestation write permissions in the final tag-release job. Actions are
pinned to commit SHAs. BSD VM actions and community container images are external
build dependencies; review their updates. No production machine is a CI target.

## Outputs and builders

| Format | Builder | Installation check |
| --- | --- | --- |
| tar.gz | Linux portable staging | Git installer unit tests |
| deb | Debian dpkg-deb | apt install/remove in container |
| rpm + src.rpm | Fedora rpmbuild | dnf install/remove in container |
| pkg.tar.zst | Arch makepkg as unprivileged builder | pacman install/remove |
| apk | Alpine abuild with ephemeral CI signing key | local key trust in disposable container |
| xbps | Void xbps-create | temporary local index and install/remove |
| txz | Slackware makepkg | installpkg/removepkg |
| macOS pkg | Hosted macOS pkgbuild | staged content inspection, actual install/help/removal |
| FreeBSD pkg | FreeBSD VM pkg create | pkg add/delete |
| OpenBSD tgz | OpenBSD VM pkg_create | pkg_add/pkg_delete |
| NetBSD tgz | NetBSD VM pkg_create | pkg_add/pkg_delete |
| Nix | flake derivation | nix build, both command names |
| Homebrew/MacPorts/Gentoo | release-specific source recipes | generated metadata, no upstream submission |

RPMs built on Fedora are not a blanket certification for all RHEL/SUSE versions.
BSD artifacts are labelled by their target OS to avoid identical .tgz filenames.
No unsigned package should be represented as distro-signed. The macOS pkg is
unsigned; Developer ID/notarization is future work. Alpine's disposable signing
key establishes a CI install test only, not a stable public trust identity.

## Local builds

```bash
bash scripts/package.sh portable
bash scripts/package.sh deb
bash scripts/package.sh rpm  # target toolchain required
python3 scripts/recipes.py dist
python3 scripts/checksums.py dist
```

Native builders require their package tools; BSD/OpenBSD packaging uses native
pkg_create interfaces. The build script stages files with install.sh, removes its
ownership manifest for native packages, and never executes updates. Build in a
disposable target OS. scripts/ci-linux.sh and ci-bsd.sh intentionally install/remove
packages and must ONLY be used inside disposable CI machines.

Nix CI generates flake.lock as an artifact, builds against that exact input and
includes the lock in the recipe bundle. Commit an audited lock before relying on
bit-for-bit reproduction across separate runs. Checksums record artifact integrity;
they do not assert deterministic binaries. Builder images/actions must also be
pinned by digest for fully reproducible infrastructure (future hardening).

## Preparing a version

1. Update VERSION, bin/updateself VERSION/help, man page and CHANGELOG together.
2. Run tests and checks; inspect every package job and target OS result.
3. Merge the reviewed PR. Tag the exact merged commit `vX.Y.Z`.
4. Review the generated draft release, checksums, provenance and platform results.
5. Publish the draft after review. Repository/registry publishing is future work.

No release tag is created by the feature implementation or by merging a PR.
