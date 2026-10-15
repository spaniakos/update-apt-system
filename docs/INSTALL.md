# Installation and removal

## From Git

Clone the existing repository, then check out a reviewed tag for a stable install:

```bash
git clone https://github.com/spaniakos/update-apt-system.git
cd update-apt-system
# git checkout v2.0.0  # after this tag has actually been released
bash install.sh --user
```

User installs use `$HOME/.local`; put `$HOME/.local/bin` on PATH yourself. The
installer never edits shell startup files. Run `updateself --dry-run` first.

System-wide installation:

```bash
sudo bash install.sh --system
# Equivalent staging-friendly interface:
sudo make install PREFIX=/usr/local
```

Custom prefix/staging:

```bash
bash install.sh --user --prefix "$HOME/tools"
bash install.sh --system --prefix /usr --destdir "$PWD/build/root"
make install PREFIX=/usr DESTDIR="$PWD/build/root"
```

Both `updateself` and `updsf` are installed. `updsf` is a relative symlink to the
main executable. An unrelated shortcut is never overwritten; disable creation
with `--no-short-command`. An existing main file must match the prior installer
manifest before replacement. Modified files cause a refusal, not an overwrite.

## Upgrade a Git/archive installation

Update your checkout to a reviewed revision and rerun the same installation
command with the same prefix. No live link to the checkout is used. The installer
copies the executable, so removing your clone does not remove the installation.
The install manifest uses POSIX `cksum` for ownership/change detection, not
cryptographic authenticity. Use release SHA-256 checksums for download integrity.

## Uninstall

```bash
bash install.sh --user --uninstall
sudo bash install.sh --system --uninstall
# Include the same --prefix if customised.
```

Only recognised, unchanged files are removed. Modified/unowned files, logs and
empty directories are retained. Keep a checkout/archive containing install.sh
for removal. Package installations must be removed through their package manager.

## Downloadable native packages

After a release exists, download the artifact built for your distribution/release,
verify `SHA256SUMS`, and install locally. These commands are examples, not an
assertion that a first release has already been published:

```bash
sudo apt install ./updateself_2.0.0-1_all.deb
sudo dnf install ./updateself-2.0.0-1.noarch.rpm
sudo pacman -U ./updateself-2.0.0-1-any.pkg.tar.zst
```

Unsigned local APK/BSD packages may need local trust flags. See the release build
report rather than disabling repository signature verification globally. The
macOS installer is unsigned unless an independent signing process is configured;
use the Git/archive installer if macOS rejects an unsigned installer. No signing
certificates are required to build it. Packages declare Bash as a prerequisite
where supported; macOS supplies Bash. There are no package post-install update runs.

## Shell completions and manual

The installer places Bash completion in `share/bash-completion/completions` and
Zsh completion in `share/zsh/site-functions` under the prefix. For user prefixes,
source the Bash file manually, or add the Zsh directory to `fpath` before compinit:

```bash
source "$HOME/.local/share/bash-completion/completions/updateself"
```

```zsh
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
autoload -Uz compinit && compinit
```

Man pages live under `share/man/man1`. Custom prefixes may require MANPATH.
The updater has no automatic background task. Schedule it yourself only after
reviewing authentication and unattended behaviour in the troubleshooting guide.
