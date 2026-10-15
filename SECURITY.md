# Security policy

The current 2.x branch receives fixes. Older APT-only scripts are not maintained
by the cross-platform implementation. Review update output and preview changes
before using an unfamiliar host. The tool invokes upstream package managers;
it cannot make third-party installers, packages or configured repositories trusted.

Report vulnerabilities privately to **spaniakos@gmail.com** with the version,
OS, installation method and a minimal reproduction without secrets. Please avoid
public exploit details until a fix is available. No response SLA is promised.

Security boundaries: no project dependency scans, no package-manager-lock removal,
no implicit root self-updaters, no externally-managed Python bypass, no repository
or trust-key modifications, no automatic restart, no implicit Nix lock-file edits.
Checksum manifests establish download integrity, not independent publisher identity.
