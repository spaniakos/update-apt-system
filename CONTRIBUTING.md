# Contributing

Keep the runtime executable self-contained and compatible with Bash 3.2. Never
use eval, automatically source user startup files, remove package-manager locks,
or run a user-owned updater as root. Preserve installation ownership and channels.

Run `make test` (Python 3 standard library), `make check` (ShellCheck recommended)
and a relevant native `scripts/package.sh FORMAT` build. Tests use temporary files
and command stubs; they never update the developer's host. Add meaningful routing,
privilege, failure and dry-run cases when adding a backend. A package build must
install/remove the artifact in an isolated environment before being called verified.

Read docs/SUPPORT.md before expanding compatibility claims. Include tested OS,
release, architecture and package result in a PR. Pin third-party GitHub Actions
to reviewed commit SHAs. Do not publish a release from pull_request_target or
with untrusted PR code holding write tokens. Do not add registry publishing yet.

See docs/RELEASING.md for versioning and release builds. Original project author:
G. Spanos (spaniakos). All changes retain GPL-3.0-only.
