#!/usr/bin/env bash
# Git/archive installer. Never performs system updates.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
PREFIX="$HOME/.local"
DESTDIR=${DESTDIR:-}
SHORT=1 REMOVE=0 MODE=user
MAN_SUBDIR=share/man
case "$(uname -s)" in OpenBSD|NetBSD) MAN_SUBDIR=man ;; esac
while [ "$#" -gt 0 ]; do
    case "$1" in
        --user) PREFIX="$HOME/.local"; MODE=user ;;
        --system) PREFIX=/usr/local; MODE=system ;;
        --prefix) [ "$#" -ge 2 ] || { echo '--prefix needs a path' >&2; exit 2; }; PREFIX=$2; shift ;;
        --destdir) [ "$#" -ge 2 ] || exit 2; DESTDIR=$2; shift ;;
        --no-short-command) SHORT=0 ;;
        --uninstall) REMOVE=1 ;;
        -h|--help) echo 'Usage: ./install.sh [--user|--system] [--prefix /path] [--destdir /stage] [--no-short-command] [--uninstall]'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
case "$PREFIX" in /*) : ;; *) echo 'Prefix must be absolute' >&2; exit 2 ;; esac
case "$DESTDIR" in ''|/*) : ;; *) echo 'DESTDIR must be absolute' >&2; exit 2 ;; esac
PREFIX=${PREFIX%/}
[ -n "$PREFIX" ] || { echo 'Refusing prefix /' >&2; exit 2; }
case "$PREFIX$DESTDIR" in *'|'*|*$'\n'*) echo 'Paths cannot contain a pipe or newline' >&2; exit 2 ;; esac
BASE="$DESTDIR$PREFIX"
MANIFEST="$BASE/share/updateself/manifest"
[ ! -L "$MANIFEST" ] || { echo 'Manifest cannot be a symlink' >&2; exit 2; }
fingerprint() { cksum < "$1" | awk '{print $1 ":" $2}'; }
owned() {
    local rel="$1" expected current
    [ -f "$MANIFEST" ] || return 1
    expected=$(awk -F'|' -v p="$rel" '$2==p {print $1}' "$MANIFEST")
    [ -n "$expected" ] || return 1
    if [ -L "$BASE/$rel" ]; then current="link:$(readlink "$BASE/$rel")"
    elif [ -f "$BASE/$rel" ]; then current=$(fingerprint "$BASE/$rel")
    else return 1; fi
    [ "$expected" = "$current" ]
}
# Fixed file list prevents tampered manifest paths from directing removals.
FILES=(bin/updateself "$MAN_SUBDIR/man1/updateself.1" "$MAN_SUBDIR/man1/updsf.1" share/bash-completion/completions/updateself share/zsh/site-functions/_updateself share/updateself/LICENSE share/updateself/README.md)
if [ "$REMOVE" -eq 1 ]; then
    [ -f "$MANIFEST" ] || { echo 'No Git/archive installation manifest found; use the package manager for packaged installations.' >&2; exit 1; }
    retained=0
    for rel in "${FILES[@]}" bin/updsf; do
        if owned "$rel"; then rm "$BASE/$rel"
        elif [ -e "$BASE/$rel" ] || [ -L "$BASE/$rel" ]; then echo "Retaining modified/unowned file: $BASE/$rel"; retained=1; fi
    done
    if [ "$retained" -eq 0 ]; then rm "$MANIFEST"; else echo 'Manifest retained so preserved files remain identifiable.'; fi
    echo 'Uninstall finished; empty directories and user logs are retained.'
    exit 0
fi
if [ "$MODE" = user ] && [ "$EUID" -eq 0 ] && [ -z "$DESTDIR" ]; then
    echo 'For a real root installation use --system or explicitly stage with --destdir.' >&2; exit 2
fi
for rel in "${FILES[@]}"; do
    if { [ -e "$BASE/$rel" ] || [ -L "$BASE/$rel" ]; } && ! owned "$rel"; then
        echo "Refusing to overwrite unowned/modified file: $BASE/$rel" >&2; exit 1
    fi
done
if [ "$SHORT" -eq 1 ]; then
    if { [ -e "$BASE/bin/updsf" ] || [ -L "$BASE/bin/updsf" ]; } && ! owned bin/updsf; then
        echo 'updsf destination exists; keeping it. Use updateself.'; SHORT=0
    elif [ -z "$DESTDIR" ]; then
        existing=$(command -v updsf || true)
        if [ -n "$existing" ] && [ "$existing" != "$PREFIX/bin/updsf" ]; then
            echo "updsf already on PATH ($existing); shortcut skipped."; SHORT=0
        fi
    fi
fi
mkdir -p "$BASE/bin" "$BASE/$MAN_SUBDIR/man1" "$BASE/share/bash-completion/completions" "$BASE/share/zsh/site-functions" "$BASE/share/updateself"
TMP=$(mktemp "$BASE/share/updateself/.manifest.XXXXXX")
trap 'rm -f "$TMP"' EXIT
install_file() {
    local src="$1" rel="$2" mode="$3"
    install -m "$mode" "$ROOT/$src" "$BASE/$rel"
    printf '%s|%s\n' "$(fingerprint "$BASE/$rel")" "$rel" >> "$TMP"
}
install_file bin/updateself bin/updateself 755
install_file man/updateself.1 "$MAN_SUBDIR/man1/updateself.1" 644
install_file man/updsf.1 "$MAN_SUBDIR/man1/updsf.1" 644
install_file completions/updateself.bash share/bash-completion/completions/updateself 644
install_file completions/_updateself share/zsh/site-functions/_updateself 644
install_file LICENSE share/updateself/LICENSE 644
install_file README.md share/updateself/README.md 644
if [ "$SHORT" -eq 1 ]; then
    if owned bin/updsf; then rm "$BASE/bin/updsf"; fi
    ln -s updateself "$BASE/bin/updsf"
    printf 'link:updateself|bin/updsf\n' >> "$TMP"
elif owned bin/updsf; then
    # Preserve a previously installed shortcut in the ownership manifest.
    printf 'link:updateself|bin/updsf\n' >> "$TMP"
fi
chmod 644 "$TMP"
mv "$TMP" "$MANIFEST"
echo "Installed updateself into $BASE/bin (shortcut=$SHORT)."
if [ -z "$DESTDIR" ]; then echo "Ensure $PREFIX/bin is on PATH. Try: updateself --dry-run"; fi
