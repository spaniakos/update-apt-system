# Embedded into bin/updateself by scripts/embed-lifecycle.py. Bash 3.2 compatible.
lc_error() { printf 'ERROR: %s\n' "$*" >&2; exit 2; }
lc_realpath() {
    local p="$1" link n=0
    case "$p" in /*) : ;; *) p="$PWD/$p" ;; esac
    while [ -L "$p" ] && [ "$n" -lt 40 ]; do
        link=$(readlink "$p") || return 1
        case "$link" in /*) p="$link" ;; *) p="${p%/*}/$link" ;; esac
        n=$((n + 1))
    done
    [ "$n" -lt 40 ] || return 1
    (cd "${p%/*}" && printf '%s/%s\n' "$(pwd -P)" "${p##*/}")
}
lc_fingerprint() { cksum < "$1" | awk '{print $1 ":" $2}'; }
lc_paths() {
    printf '%s\n' bin/updateself bin/updsf "$LC_MAN/man1/updateself.1" "$LC_MAN/man1/updsf.1" \
        share/bash-completion/completions/updateself share/zsh/site-functions/_updateself \
        share/updateself/LICENSE share/updateself/README.md
}
lc_owned() {
    local rel="$1" expected actual
    expected=$(awk -F'|' -v p="$rel" '$2==p {print $1}' "$LC_MANIFEST")
    [ -n "$expected" ] || return 1
    if [ -L "$LC_PREFIX/$rel" ]; then actual="link:$(readlink "$LC_PREFIX/$rel")"
    elif [ -f "$LC_PREFIX/$rel" ]; then actual=$(lc_fingerprint "$LC_PREFIX/$rel")
    else return 1; fi
    [ "$actual" = "$expected" ]
}
lc_safe_parents() {
    local rel parent part cursor
    while IFS= read -r rel; do
        parent=${rel%/*}; cursor="$LC_PREFIX"
        while [ -n "$parent" ]; do
            part=${parent%%/*}; cursor="$cursor/$part"
            [ ! -L "$cursor" ] || lc_error "Refusing symlinked installation directory: $cursor"
            if [ "$parent" = "$part" ]; then break; fi
            parent=${parent#*/}
        done
    done < <(lc_paths)
}
lc_safe_layout() {
    [ -f "$LC_MANIFEST" ] && [ ! -L "$LC_MANIFEST" ] || lc_error 'Missing or symlinked ownership manifest'
    lc_safe_parents
}
lc_claim() {
    [ -z "$LC_MANAGER" ] || lc_error 'Multiple installation owners found; resolve ownership manually'
    LC_MANAGER=$1; LC_ID=${2:-updateself}; LC_SCOPE=${3:-root}
}
lc_detect() {
    local owner='' prefix='' record='' store='' entry=''
    LC_ENTRY=${BASH_SOURCE[0]}
    LC_REAL=$(lc_realpath "$LC_ENTRY") || lc_error 'Cannot resolve the running executable'
    LC_PREFIX=${LC_REAL%/bin/*}; LC_MANAGER='' LC_ID=updateself LC_SCOPE=root
    LC_MAN=share/man; case "$(uname -s)" in OpenBSD|NetBSD) LC_MAN='man' ;; esac
    case "$LC_REAL" in
        */Cellar/updateself/*/bin/updateself)
            command -v brew >/dev/null || lc_error 'Homebrew owner is unavailable'
            prefix=$(brew --prefix updateself) || lc_error 'Cannot query Homebrew ownership'
            [ "$(lc_realpath "$prefix/bin/updateself")" = "$LC_REAL" ] || lc_error 'Homebrew ownership mismatch'
            lc_claim brew updateself user ;;
        /nix/store/*/bin/*)
            store=${LC_REAL%/bin/*}
            if command -v nix >/dev/null && command -v python3 >/dev/null; then
                entry=$(nix profile list --json 2>/dev/null | python3 -c 'import json,sys
data=json.load(sys.stdin).get("elements", {})
items=data.items() if isinstance(data,dict) else enumerate(data)
matches=[str(k) for k,v in items if sys.argv[1] in v.get("storePaths",[])]
if len(matches)!=1: sys.exit(1)
print(matches[0])' "$store") || entry=''
                if [[ "$entry" =~ ^[A-Za-z0-9_.+-]+$ ]]; then lc_claim nix-profile "$entry" user; fi
            fi
            if [ -z "$LC_MANAGER" ] && command -v nix-env >/dev/null; then
                entry=$(nix-env -q --out-path 2>/dev/null | awk -v p="$store" '$2==p {print $1}')
                if [[ "$entry" =~ ^updateself-[A-Za-z0-9_.+-]+$ ]]; then lc_claim nix-env "$entry" user; fi
            fi
            [ -n "$LC_MANAGER" ] || lc_error 'Nix store owner is ambiguous/declarative; update or remove it in its owning configuration/profile (modern profile detection needs python3)' ;;
    esac
    if command -v dpkg-query >/dev/null && owner=$(dpkg-query -S "$LC_REAL" 2>/dev/null); then
        case "$owner" in "updateself: $LC_REAL"|"updateself:"*": $LC_REAL") lc_claim apt ;; *) lc_error 'Executable belongs to another Debian package' ;; esac
    fi
    if command -v rpm >/dev/null && owner=$(rpm -qf --qf '%{NAME}\n' "$LC_REAL" 2>/dev/null); then
        [ "$owner" = updateself ] || lc_error 'Executable belongs to another RPM package'
        if command -v zypper >/dev/null; then lc_claim zypper
        elif command -v dnf5 >/dev/null; then lc_claim dnf5
        elif command -v dnf >/dev/null; then lc_claim dnf
        elif command -v yum >/dev/null; then lc_claim yum
        else lc_error 'No RPM package manager is available'; fi
    fi
    if command -v pacman >/dev/null && owner=$(pacman -Qqo "$LC_REAL" 2>/dev/null); then
        [ "$owner" = updateself ] || lc_error 'Executable belongs to another Arch package'; lc_claim pacman
    fi
    if command -v apk >/dev/null && owner=$(apk info --who-owns "$LC_REAL" 2>/dev/null); then
        case "$owner" in *' is owned by updateself-'[0-9]*) lc_claim apk ;; *) lc_error 'Executable belongs to another Alpine package' ;; esac
    fi
    if command -v xbps-query >/dev/null && owner=$(xbps-query -o "$LC_REAL" 2>/dev/null) && [ -n "$owner" ]; then
        case "$owner" in updateself-[0-9]*": $LC_REAL") lc_claim xbps ;; *) lc_error 'Executable belongs to another Void package' ;; esac
    fi
    case "$(uname -s)" in
        Darwin)
            if [ "$LC_REAL" = "/usr/local/bin/updateself" ] && pkgutil --pkg-info gr.makeasite.updateself >/dev/null 2>&1; then lc_claim macos-pkg; fi
            if command -v port >/dev/null && owner=$(port provides "$LC_REAL" 2>/dev/null); then
                case "$owner" in *'provided by: updateself') lc_claim macports ;; esac
            fi ;;
        FreeBSD)
            if owner=$(pkg which -q "$LC_REAL" 2>/dev/null); then
                case "$owner" in updateself-[0-9]*) lc_claim freebsd ;; *) lc_error 'Executable belongs to another FreeBSD package' ;; esac
            fi ;;
        OpenBSD|NetBSD)
            local query=-Fe
            [ "$(uname -s)" != OpenBSD ] || query=-E
            if owner=$(pkg_info "$query" "$LC_REAL" 2>/dev/null); then
                case "$owner" in updateself-[0-9]*)
                    if [ "$(uname -s)" = OpenBSD ]; then lc_claim openbsd "$owner"; else lc_claim netbsd "$owner"; fi ;;
                *) lc_error 'Executable belongs to another BSD package' ;;
                esac
            fi ;;
    esac
    for record in /var/db/pkg/*/updateself-[0-9]*/CONTENTS; do
        if [ -f "$record" ] && awk -v p="$LC_REAL" '$1=="obj" && $2==p {found=1} END {exit !found}' "$record"; then
            owner=${record%/CONTENTS}; owner=${owner%/*}; lc_claim gentoo "${owner##*/}/updateself"
        fi
    done
    for record in /var/log/packages/updateself-[0-9]*; do
        if [ -f "$record" ] && grep -Fx "${LC_REAL#/}" "$record" >/dev/null; then lc_claim slackware; fi
    done
    LC_MANIFEST="$LC_PREFIX/share/updateself/manifest"
    if [ -z "$LC_MANAGER" ] && [ -f "$LC_MANIFEST" ]; then
        case "$LC_REAL" in */bin/updateself) : ;; *) lc_error 'Unrecognised installation layout' ;; esac
        lc_claim archive updateself user
        [ -w "$LC_REAL" ] && [ -w "$LC_PREFIX/bin" ] || LC_SCOPE=root
    fi
    [ -n "$LC_MANAGER" ] || lc_error 'No recognised installation owner; use the original installer/package manager (source checkouts are not installed copies)'
    if [ "$LC_MANAGER" = macos-pkg ]; then LC_MANIFEST="$LC_PREFIX/share/updateself/package-manifest"; fi
    case "$LC_MANAGER" in archive|macos-pkg) lc_safe_layout ;; esac
    if [ "$EUID" -eq 0 ] && [ "$LC_SCOPE" = user ] && [ "$LC_MANAGER" != archive ]; then
        lc_error 'Run this self-management command as the account that owns the package manager'
    fi
}
lc_plan() {
    LC_COMMAND=()
    if [ "$LC_ACTION" = uninstall ]; then
        case "$LC_MANAGER" in
            apt) LC_COMMAND=(apt-get remove -y updateself) ;;
            dnf|dnf5|yum) LC_COMMAND=("$LC_MANAGER" remove -y updateself) ;;
            zypper) LC_COMMAND=(zypper --non-interactive remove updateself) ;;
            pacman) LC_COMMAND=(pacman -R --noconfirm updateself) ;;
            apk) LC_COMMAND=(apk del updateself) ;;
            xbps) LC_COMMAND=(xbps-remove -y updateself) ;;
            slackware) LC_COMMAND=(removepkg updateself) ;;
            gentoo) LC_COMMAND=(emerge --ask=n --unmerge "$LC_ID") ;;
            freebsd) LC_COMMAND=(pkg delete -y updateself) ;;
            openbsd|netbsd) LC_COMMAND=(pkg_delete "$LC_ID") ;;
            brew) LC_COMMAND=(brew uninstall updateself) ;;
            macports) LC_COMMAND=(port uninstall updateself) ;;
            nix-profile) LC_COMMAND=(nix profile remove "$LC_ID") ;;
            nix-env) LC_COMMAND=(nix-env --uninstall "$LC_ID") ;;
        esac
    else
        case "$LC_MANAGER" in
            apt) LC_COMMAND=(apt-get install --only-upgrade -y updateself) ;;
            dnf|dnf5|yum) LC_COMMAND=("$LC_MANAGER" upgrade -y updateself) ;;
            zypper) LC_COMMAND=(zypper --non-interactive update updateself) ;;
            pacman) LC_COMMAND=(pacman -S --needed --noconfirm updateself) ;;
            apk) LC_COMMAND=(apk upgrade updateself) ;;
            xbps) LC_COMMAND=(xbps-install -u -y updateself) ;;
            slackware) LC_COMMAND=(slackpkg -batch=on -default_answer=y upgrade updateself) ;;
            gentoo) LC_COMMAND=(emerge --ask=n --update "$LC_ID") ;;
            freebsd) LC_COMMAND=(pkg upgrade -y updateself) ;;
            openbsd) LC_COMMAND=(pkg_add -u updateself) ;;
            netbsd) LC_COMMAND=(pkgin -y install updateself) ;;
            brew) LC_COMMAND=(brew upgrade updateself) ;;
            macports) LC_COMMAND=(port upgrade updateself) ;;
            nix-profile) LC_COMMAND=(nix profile upgrade "$LC_ID") ;;
            nix-env) LC_COMMAND=(nix-env --upgrade "$LC_ID") ;;
        esac
    fi
    printf 'Installation: %s | executable: %s\n' "$LC_MANAGER" "$LC_REAL"
    if [ "$LC_ACTION" = check-self-update ]; then printf 'Check latest stable GitHub release metadata (read-only).\n'; return; fi
    if [ "${#LC_COMMAND[@]}" -gt 0 ]; then printf 'Command: '; printf '%q ' "${LC_COMMAND[@]}"; printf '\n'
    elif [ "$LC_ACTION" = uninstall ]; then printf 'Remove unchanged owned files from %s; retain modified/unrelated files.\n' "$LC_PREFIX"
    else printf 'Download and verify the latest stable %s release; reinstall in %s.\n' "$LC_MANAGER" "$LC_PREFIX"; fi
}
lc_newer() {
    local IFS=. a b c x y z
    read -r a b c <<< "$1"; read -r x y z <<< "$2"
    if [ "$((10#$a))" -ne "$((10#$x))" ]; then [ "$((10#$a))" -gt "$((10#$x))" ]; return; fi
    if [ "$((10#$b))" -ne "$((10#$y))" ]; then [ "$((10#$b))" -gt "$((10#$y))" ]; return; fi
    [ "$((10#$c))" -gt "$((10#$z))" ]
}
lc_latest() {
    local url
    command -v curl >/dev/null || lc_error 'curl is required for GitHub release discovery'
    url=$(curl --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 15 --max-time 60 -fsSLI -o /dev/null -w '%{url_effective}' "$LC_REPO/releases/latest") || lc_error 'Cannot discover the latest stable release'
    case "$url" in "$LC_REPO/releases/tag/v"*) LC_LATEST=${url##*/v} ;; *) lc_error 'Unexpected release redirect' ;; esac
    [[ "$LC_LATEST" =~ ^[0-9]{1,6}\.[0-9]{1,6}\.[0-9]{1,6}$ ]] || lc_error 'Invalid stable release version'
    printf 'Installed: %s | latest stable GitHub release: %s\n' "$VERSION" "$LC_LATEST"
}
lc_command() {
    if [ "$LC_SCOPE" = user ] || [ "$EUID" -eq 0 ]; then "$@"
    elif command -v sudo >/dev/null; then sudo -- "$@"
    elif command -v doas >/dev/null; then doas "$@"
    else lc_error 'Administrator access requires sudo/doas or root'; fi
}
lc_download() {
    local asset="$1" expected actual
    curl --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 15 --max-time 300 -fsSL \
        "$LC_REPO/releases/download/v$LC_LATEST/SHA256SUMS" -o "$LC_WORK/SHA256SUMS" || return 1
    expected=$(awk -v n="$asset" '$2==n {print $1}' "$LC_WORK/SHA256SUMS")
    [[ "$expected" =~ ^[a-f0-9]{64}$ ]] || lc_error 'Release checksum missing, invalid or duplicated'
    curl --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 15 --max-time 300 -fsSL \
        "$LC_REPO/releases/download/v$LC_LATEST/$asset" -o "$LC_WORK/$asset" || return 1
    if command -v sha256sum >/dev/null; then actual=$(sha256sum "$LC_WORK/$asset" | awk '{print $1}')
    elif command -v shasum >/dev/null; then actual=$(shasum -a 256 "$LC_WORK/$asset" | awk '{print $1}')
    else lc_error 'SHA-256 verification requires sha256sum or shasum'; fi
    [ "$actual" = "$expected" ] || lc_error 'Release checksum mismatch; nothing installed'
    printf 'SHA-256 verified: %s\n' "$asset"
    if command -v gh >/dev/null; then
        gh attestation verify "$LC_WORK/$asset" --repo spaniakos/updateself || lc_error 'Provenance verification failed'
    else printf 'GitHub CLI unavailable; verified HTTPS release checksum only (not code signing).\n'; fi
}
lc_remove() {
    local rel retained=0
    lc_safe_layout
    while IFS= read -r rel; do
        if lc_owned "$rel"; then lc_command rm -- "$LC_PREFIX/$rel" || return 1
        elif [ -e "$LC_PREFIX/$rel" ] || [ -L "$LC_PREFIX/$rel" ]; then
            printf 'Retaining modified/unowned file: %s\n' "$LC_PREFIX/$rel"; retained=1
        fi
    done < <(lc_paths)
    if [ "$retained" -ne 0 ]; then printf 'Ownership manifest and package receipt retained.\n'; return 1; fi
    lc_command rm -- "$LC_MANIFEST" || return 1
    if [ "$LC_MANAGER" = macos-pkg ]; then lc_command pkgutil --forget gr.makeasite.updateself || return 1; fi
    printf 'Uninstalled updateself. Shared directories and user logs retained.\n'
}
lc_require_unchanged() {
    local rel
    lc_safe_layout
    while IFS= read -r rel; do
        if [ -e "$LC_PREFIX/$rel" ] || [ -L "$LC_PREFIX/$rel" ]; then
            lc_owned "$rel" || lc_error "Modified/unowned file prevents self-update: $rel"
        fi
    done < <(lc_paths)
}
lc_archive_update() {
    local asset="updateself-$LC_LATEST.tar.gz" path rel short=0
    lc_require_unchanged
    lc_download "$asset" || return 1
    # Reject traversal, absolute entries, and links/special files before extraction.
    tar -tzf "$LC_WORK/$asset" > "$LC_WORK/entries" || return 1
    while IFS= read -r path; do
        case "$path" in "updateself-$LC_LATEST/"*) : ;; *) lc_error 'Unsafe archive root' ;; esac
        case "/$path/" in *'/../'*|*'/./'*) lc_error 'Unsafe archive entry' ;; esac
    done < "$LC_WORK/entries"
    tar -tvzf "$LC_WORK/$asset" | awk 'substr($0,1,1)!="-" && substr($0,1,1)!="d" {bad=1} END {exit bad}' || lc_error 'Archive links/special files are not accepted'
    mkdir "$LC_WORK/source" "$LC_WORK/backup"
    tar -xzf "$LC_WORK/$asset" -C "$LC_WORK/source" || return 1
    [ -f "$LC_WORK/source/updateself-$LC_LATEST/install.sh" ] || lc_error 'Release installer missing'
    while IFS= read -r rel; do
        if [ -e "$LC_PREFIX/$rel" ] || [ -L "$LC_PREFIX/$rel" ]; then
            mkdir -p "$LC_WORK/backup/${rel%/*}"
            lc_command cp -pP "$LC_PREFIX/$rel" "$LC_WORK/backup/$rel" || return 1
        fi
    done < <(lc_paths)
    lc_command cp -p "$LC_MANIFEST" "$LC_WORK/backup/manifest"
    # Preserve recovery files if interrupted during installation or rollback.
    # shellcheck disable=SC2034
    LC_KEEP=1
    lc_owned bin/updsf && short=1
    local args=(--system --prefix "$LC_PREFIX")
    if [ "$LC_SCOPE" = user ] && [ "$EUID" -ne 0 ]; then args=(--user --prefix "$LC_PREFIX"); fi
    [ "$short" -eq 1 ] || args+=(--no-short-command)
    if ! lc_command "$BASH" "$LC_WORK/source/updateself-$LC_LATEST/install.sh" "${args[@]}" ||
        [ "$("$LC_PREFIX/bin/updateself" --version)" != "$LC_LATEST" ]; then
        printf 'Installation failed; restoring previous managed files.\n' >&2
        lc_safe_parents
        while IFS= read -r rel; do
            if [ -e "$LC_WORK/backup/$rel" ] || [ -L "$LC_WORK/backup/$rel" ]; then
                if [ -e "$LC_PREFIX/$rel" ] || [ -L "$LC_PREFIX/$rel" ]; then lc_command rm -- "$LC_PREFIX/$rel" || lc_error 'Cannot clear destination for rollback'; fi
                lc_command cp -pP "$LC_WORK/backup/$rel" "$LC_PREFIX/$rel" || { LC_KEEP=1; lc_error "Rollback failed: $rel; backup retained at $LC_WORK"; }
            elif [ -e "$LC_PREFIX/$rel" ] || [ -L "$LC_PREFIX/$rel" ]; then
                lc_command rm -- "$LC_PREFIX/$rel" || lc_error 'Cannot remove newly created managed file during rollback'
            fi
        done < <(lc_paths)
        # LC_KEEP is read by the generated helper's EXIT trap.
        # shellcheck disable=SC2034
        if [ -e "$LC_MANIFEST" ] || [ -L "$LC_MANIFEST" ]; then lc_command rm -- "$LC_MANIFEST" || lc_error 'Cannot clear manifest for rollback'; fi
        lc_command cp -p "$LC_WORK/backup/manifest" "$LC_MANIFEST" || { LC_KEEP=1; lc_error "Manifest rollback failed; backup retained at $LC_WORK"; }
        LC_KEEP=0
        return 1
    fi
    # shellcheck disable=SC2034
    LC_KEEP=0
    printf 'Updated updateself to %s in %s.\n' "$LC_LATEST" "$LC_PREFIX"
}
lc_perform() {
    if [ "$LC_ACTION" = uninstall ]; then
        case "$LC_MANAGER" in archive|macos-pkg) lc_remove ;; *) lc_command "${LC_COMMAND[@]}" ;; esac
    elif [ "$LC_MANAGER" = archive ]; then lc_archive_update
    elif [ "$LC_MANAGER" = macos-pkg ]; then
        local arch asset
        lc_require_unchanged
        arch=$(uname -m); case "$arch" in arm64|x86_64) : ;; *) lc_error 'Unsupported macOS architecture' ;; esac
        asset="updateself-$LC_LATEST-macos-$arch.pkg"
        lc_download "$asset" || return 1
        lc_command /usr/sbin/installer -pkg "$LC_WORK/$asset" -target /
    else
        printf 'Using the owning manager. Its configured channel may lag GitHub; no repository is added.\n'
        lc_command "${LC_COMMAND[@]}"
    fi
}
lc_start() {
    local arg answer='' function_name lock
    LC_ACTION=$SELF_ACTION; LC_REPO=https://github.com/spaniakos/updateself; LC_LATEST=''
    for arg in "${ORIGINAL_ARGS[@]}"; do
        case "$arg" in --uninstall|--self-update|--check-self-update|--dry-run|--yes|-y|--ask|-n|--no-color) : ;;
            *) lc_error 'Self-management accepts only one action plus --dry-run, --yes/--ask and --no-color' ;;
        esac
    done
    lc_detect
    lc_plan
    if [ "$DRY" -eq 1 ]; then printf 'Preview only: no network requests, files, locks or mutations.\n'; return 0; fi
    if [ "$LC_ACTION" != uninstall ]; then
        lc_latest
        [ "$LC_ACTION" != check-self-update ] || return 0
        if ! lc_newer "$LC_LATEST" "$VERSION"; then printf 'No newer stable release; no downgrade or reinstall performed.\n'; return 0; fi
    fi
    if [ "$SELF_YES" -ne 1 ]; then
        [ -t 0 ] || lc_error 'Self-management requires confirmation; review --dry-run, then pass --yes for noninteractive use'
        printf 'Proceed with %s? [y/N] ' "$LC_ACTION"; IFS= read -r answer || answer=''
        case "$answer" in y|Y|yes|YES) : ;; *) printf 'Cancelled; nothing changed.\n'; return 0 ;; esac
    fi
    # A separate private helper survives removal/replacement of this executable.
    lock="${TMPDIR:-/tmp}/updateself-$EUID.lock"
    (umask 077; mkdir "$lock") 2>/dev/null || { printf 'Another invocation or stale lock exists.\n' >&2; return 75; }
    LC_WORK=$(umask 077; mktemp -d "${TMPDIR:-/tmp}/updateself-lifecycle.XXXXXX") || { rmdir "$lock"; return 1; }
    {
        printf '#!/usr/bin/env bash\nset -euo pipefail\n'
        for function_name in $(compgen -A function lc_); do declare -f "$function_name"; done
        for arg in LC_ACTION LC_REPO LC_LATEST LC_ENTRY LC_REAL LC_PREFIX LC_MANAGER LC_ID LC_SCOPE LC_MAN LC_MANIFEST LC_WORK VERSION; do
            printf '%s=%q\n' "$arg" "${!arg}"
        done
        printf 'LC_COMMAND=('; printf '%q ' ${LC_COMMAND[@]+"${LC_COMMAND[@]}"}; printf ')\n'
        printf 'LC_LOCK=%q\nLC_KEEP=0\n' "$lock"
        printf 'trap '\''rmdir "$LC_LOCK" 2>/dev/null || :; if [ "$LC_KEEP" -eq 0 ]; then rm -rf "$LC_WORK"; else printf "Recovery files retained at %%s\\n" "$LC_WORK" >&2; fi'\'' EXIT\n'
        printf 'trap '\''exit 130'\'' INT\ntrap '\''exit 143'\'' TERM\n'
        printf 'lc_perform\n'
    } > "$LC_WORK/helper.bash"
    exec "$BASH" "$LC_WORK/helper.bash"
}
