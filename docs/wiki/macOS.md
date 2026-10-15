# macOS

Run as your normal user, without putting sudo before the whole updater.
macOS's built-in Bash is supported.

| Component | Behaviour |
| --- | --- |
| brew | Update metadata, formulae and macOS casks |
| macports | Update MacPorts metadata and outdated ports |
| apple | List applicable Apple updates by default |
| mas | Update App Store applications through installed mas |

```bash
updateself --dry-run
updateself --only brew --ask
updateself --only brew --greedy --cleanup
updateself --only apple
updateself --only apple --base-install --ask
```

Homebrew honours the target user's PATH, supplemented with Intel and Apple
Silicon standard locations. Only the selected installation is updated; review the
printed path if both are installed. --greedy includes latest/self-updating casks.
Close applications before upgrades; cask installers can request authentication.

**--base-install installs ALL applicable Apple updates, possibly a major macOS
upgrade.** --apple-install is an alias. No --restart is passed, but a restart may
be needed. The updater does not sign in to your Apple account.

Unsigned Intel/Apple Silicon .pkg installers are built by CI. Signing/notarization
is future work. See [[Installation]], [[Supported Tools|Supported-Tools]],
[[Python and pip|Python-and-pip]] and [[Nix]].
