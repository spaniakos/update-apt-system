# Supported tools and ownership

Detected tools are updated through their installation owner. Missing helpers are
never installed; uncertain manual layouts are skipped.

| Component | Updater / supported user layout |
| --- | --- |
| rust | rustup update; .cargo/bin |
| composer | composer self-update; standalone PHAR in .local/bin |
| uv | uv self update; standalone .local/bin; also uv tool upgrade --all |
| bun | bun upgrade; .bun/bin |
| deno | deno upgrade; .deno/bin; detected LTS retained, prereleases skipped |
| poetry | poetry self update; official .local/share/pypoetry installation |
| rclone | rclone selfupdate; standalone .local/bin |
| yt-dlp | yt-dlp -U; official .local/bin binary, current channel retained |
| pipx | pipx upgrade-all for its isolated CLI environments |
| python | Read-only discovery; explicitly selected pip environments |
| clamav | FreshClam signatures; skip an active FreshClam daemon |
| npm — optional | Semver-compatible globals in the active home-owned prefix |
| cargo — optional | Installed binaries through an existing cargo-update helper |
| aur — optional | Installed paru/yay, selected user, Arch-based host |

```bash
updateself --only rust,composer,uv,pipx --ask
updateself --include npm,cargo,aur --ask
updateself --skip rust,deno
```

Homebrew/native/Nix/pipx/uv/npm-managed executables stay with their owner.
Another manual path can be skipped even when the command exists. Do not use
sudo to force a skipped self-updater. No project dependency scan, automatic npm
major migration, helper installation, daemon stop or package-lock removal occurs.

User operations apply to the invoking account, SUDO_USER or explicit --user.
They never iterate all accounts or implicitly use root. See [[Python and pip|Python-and-pip]],
[[Nix]] and [[Platform Support|Platform-Support]].
