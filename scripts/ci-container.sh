#!/bin/sh
# Bootstrap Bash in minimal disposable build images, using their own manager.
set -eu
if ! command -v bash >/dev/null 2>&1; then
    case "$1" in
        apk) apk add --no-cache bash ;;
        xbps) xbps-install -Syu xbps; xbps-install -y bash ;;
        *) echo 'Build image is missing Bash' >&2; exit 1 ;;
    esac
fi
exec bash /src/scripts/ci-linux.sh "$1"
