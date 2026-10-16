# CI, packages and releases

## Triggers

- Pull requests and pushes to master: syntax, ShellCheck, unit/installer tests,
  package generation, disposable installation/removal checks and release-preview assembly.
- Manual **Release packages** with **mode=preview** (default): the full build matrix,
  release assembly and checksum verification. No tag, attestation or release mutation.
- Manual **Release packages** with **mode=create-draft** on **master**: validate the
  requested tag against VERSION and the finalized changelog, run the full build,
  generate provenance, create the tag at the built commit, and populate a draft.
- `vX.Y.Z` tag: require VERSION/runtime/man consistency, run checks/builds, collect
  all 13 required package bundles, release notes, a build report, checksums and
  provenance, then create or reuse a **draft GitHub Release**.
  Review the build report and publish the draft manually. No registry submission.

Builds have no package-repository publishing credentials. GITHUB_TOKEN only gets
release/attestation write permissions in the final draft-release job. Actions are
pinned to reviewed commit SHAs. Checkout and artifact actions use Node 24 and
require runner 2.327.1 or newer; GitHub-hosted runners satisfy this requirement. BSD VM actions and community container images are external
build dependencies; review their updates. No production machine is a CI target.

## Release entirely from github.com

1. After the finalization PR is merged, wait for **master** CI to pass.
2. Optionally open **Releases → Draft a new release**, select the new tag name and
   target **master**, enter your title/notes, and **Save draft**. Saving a draft does
   not create the Git tag or start builds.
3. Open **Actions → Release packages → Run workflow**.
4. Select branch **master**, choose **mode=create-draft**, and enter the exact tag
   matching VERSION, for example **v2.0.0**. Then click **Run workflow**.
5. Wait for every job, including **draft-release**, to succeed. The workflow builds
   and verifies all packages before creating the tag at that exact built commit.
6. Open the saved/generated draft under **Releases**, review its downloads,
   checksums and notes, then click **Publish release**.

Existing draft titles and release-note bodies are preserved. If no draft exists,
the workflow creates one from docs/releases/X.Y.Z.md. It never publishes a release.
Do not publish the draft while the workflow is uploading its assets.

Matching filenames in an unpublished draft are replaced when retrying an upload;
unrelated filenames and the draft's title/notes are retained. A published release
or a tag pointing at another commit causes failure rather than modification.
An existing matching lightweight or annotated tag is reused without moving it.
Retry the same Actions run after a transient upload failure, so its source commit
stays the same. A new run from a newer master commit cannot move an existing tag.

Tags created using the built-in GITHUB_TOKEN do not trigger another tag-push
workflow. The manual run therefore completes builds, tagging and draft upload
itself; no additional token or secret is required. CLI-created matching tag pushes
remain supported and also reuse existing drafts.

## Finding downloads

- Development packages: open **Actions → CI → a successful run → Artifacts**.
  These downloads require GitHub sign-in and expire according to Actions retention.
- Release previews: open **Actions → CI → a successful run → Artifacts → release-preview**,
  or the equivalent artifact in a manual **Release packages** run. It contains the exact layout used for release assets.
- Published versions: [GitHub Releases](https://github.com/spaniakos/updateself/releases).
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
4. Manually run **Release packages** with **mode=preview** on the preparation branch. Confirm the full
   build matrix and assembly job pass. Download release-preview and verify its
   checksums, report and expected platform assets.
5. Finalize the CHANGELOG release date, rerun checks, and merge the reviewed PR.
   Use **mode=create-draft** from master, or tag that exact merged commit `vX.Y.Z`
   through Git. A mismatched tag or missing/invalid release date is rejected.
6. The release run rebuilds and validates packages, verifies downloaded checksums,
   generates provenance and creates or populates an unpublished draft.
7. Review the draft and verify downloads before publishing it. Confirm the public
   Releases page and README/Wiki links work. Registry submission remains future work.

The final attestation and draft-population steps run only for matching pushed tags
or explicit create-draft requests on master, and are skipped in preview mode. A successful preview validates collection
and checksums; it does not claim those tag-only steps have already run.

To verify all assets after downloading them together:

```bash
sha256sum -c SHA256SUMS              # Linux
shasum -a 256 -c SHA256SUMS          # macOS
gh attestation verify PACKAGE --repo spaniakos/updateself
```

Replace PACKAGE with a downloaded package filename. Attestations verify provenance;
they do not replace platform code signing or distribution signing.

No release tag is created by merging a PR or running preview mode.

References:
- https://docs.github.com/en/actions/concepts/security/github_token
- https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
