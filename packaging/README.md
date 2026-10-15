# Package metadata

Native package metadata is generated in `scripts/package.sh` from `VERSION` and
the shared installer staging tree. This avoids maintaining different executable
payloads in Debian, RPM, Arch, Alpine, Void, Slackware, macOS and BSD packages.

`scripts/recipes.py` generates release-specific Homebrew, MacPorts and Gentoo
recipes with source checksums. `flake.nix` is the Nix package definition.

The Git installer manifest is removed from native packages; their package manager
owns installation/removal. Packages never run updates in post-install hooks.
No generated recipe is submitted to an upstream registry in this phase.
