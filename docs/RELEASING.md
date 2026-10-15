# CI, packages and releases

## Triggers

- Pull requests and pushes to master: syntax, ShellCheck, unit/installer tests,
  package generation and disposable installation/removal checks.
- Manual **Release packages** dispatch on a branch: the same build matrix, full
  release-asset assembly, checksum verification and a **release-preview** artifact.
  This creates no tag, attestation or GitHub Release.
- `vX.Y.Z` tag: require VERSION/runtime/man consistency, run checks/builds, collect
  all 13 required package bundles, release notes, a build report, checksums and
  provenance, then create a **draft GitHub Release**.
  Review the build report and publish the draft manually. No registry submission.

Builds have no package-repository publishing credentials. GITHUB_TOKEN only gets
release/attestation write permissions in the final tag-release job. Actions are
pinned to reviewed commit SHAs. Checkout and artifact actions use Node 24 and
require runner 2.327.1 or newer; GitHub-hosted runners satisfy this requirement. BSD VM actions and community container images are external
build dependencies; review their updates. No production machine is a CI target.

## Finding downloads

- Development packages: open **Actions → CI → a successful run → Artifacts**.
  These downloads require GitHub sign-in and expire according to Actions retention.
- Release previews: open **Actions → Release packages → a successful manual run →
  Artifacts → release-preview**. It contains the exact layout used for release assets.
- Published versions: [GitHub Releases](https://github.com/spaniakos/update-apt-system/releases).
  Installers and archives appear under **Assets**, alongside SHA256SUMS,
  RELEASE-NOTES.md and BUILD-REPORT.md. Drafts are visible only to maintainers.
- **GitHub Packages** is a separate registry, not the location of these installers.
  No distribution-repository or registry submission is performed.

Merging a PR builds development artifacts; it does not create a version tag or
publish a release. Public downloads appear only after a draft release is published.

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
NetBSD/FreeBSD artifacts are labelled by their target OS. OpenBSD's .tgz retains
its canonical updateself-VERSION.tgz name because pkg_add validates that basename.
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

Nix input is pinned in the committed flake.lock, taken from a passing Nix build.
CI refuses implicit lock updates and includes that lock in the recipe bundle.
Checksums record artifact integrity; they do not assert deterministic binaries.
Builder images/actions must also be
pinned by digest for fully reproducible infrastructure (future hardening).

## Preparing a version

1. Update VERSION, bin/updateself VERSION/help, man page and CHANGELOG together.
2. Run tests and checks; inspect every package job and target OS result.
3. Update docs/releases/X.Y.Z.md with user-facing release notes and package limitations.
4. Manually run **Release packages** on the preparation branch. Confirm the full
   build matrix and assembly job pass. Download release-preview and verify its
   checksums, report and expected platform assets.
5. Finalize the CHANGELOG release date, rerun checks, and merge the reviewed PR.
   Tag that exact merged commit `vX.Y.Z`. Tags whose version differs from VERSION,
   or whose changelog still says unreleased, are rejected.
6. The tag run rebuilds and validates packages, verifies downloaded checksums,
   generates provenance attestations and creates a draft with authored release notes.
7. Review the draft and verify downloads before publishing it. Confirm the public
   Releases page and README/Wiki links work. Registry submission remains future work.

The final attestation and draft-creation steps require a real version tag and are
intentionally skipped in branch previews. A successful preview validates collection
and checksums; it does not claim those tag-only steps have already run.

To verify all assets after downloading them together:

```bash
sha256sum -c SHA256SUMS              # Linux
shasum -a 256 -c SHA256SUMS          # macOS
gh attestation verify PACKAGE --repo spaniakos/update-apt-system
```

Replace PACKAGE with a downloaded package filename. Attestations verify provenance;
they do not replace platform code signing or distribution signing.

No release tag is created by the feature implementation or by merging a PR.
