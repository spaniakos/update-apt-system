# Linux

The native backend comes from distribution identity, not merely from installed
package-manager commands.

| Family | Normal update |
| --- | --- |
| Debian/Ubuntu and derivatives | APT refresh and upgrade |
| Fedora/RHEL/Rocky/Alma/CentOS Stream | DNF5/DNF upgrade, with YUM fallback |
| Arch/Manjaro/EndeavourOS | Complete Pacman -Syu transaction |
| openSUSE Leap/SLES | Zypper refresh/update |
| openSUSE Tumbleweed | Zypper refresh/dup |
| Alpine | APK refresh/upgrade |
| Void | XBPS bootstrap and remaining updates |
| Gentoo | Portage sync, world and preserved rebuild |
| Slackware | Slackpkg refresh, new packages and upgrades |

```bash
updateself --only system --dry-run
updateself --only system --ask
updateself --only system --full-upgrade --ask
updateself --only snap,flatpak --ask
updateself --include npm,cargo,aur --ask
```

--full-upgrade selects APT dist-upgrade and may remove packages. --cleanup enables
backend-specific cleanup after successful prerequisites. Arch orphan deletion,
Gentoo depclean and Slackware clean-system remain manual review tasks.

Snap refreshes system packages. Flatpak covers default/named system installations
and the selected non-root user's installation. With root, use --user alice for
that account's user tools; other accounts are not scanned. --cleanup can remove
unused Flatpak runtimes after updates succeed.

Existing repositories, release branches, holds and pins are retained. No distro
migration or repository change is made. OSTree/bootc/transactional native updates
are currently unsupported; app components can still run. See [[Nix]] for NixOS,
[[Supported Tools|Supported-Tools]] and [[Platform Support|Platform-Support]].
