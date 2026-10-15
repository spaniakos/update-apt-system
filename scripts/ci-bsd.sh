#!/usr/bin/env bash
# Invoked in the disposable BSD VM used by GitHub Actions.
set -euo pipefail
FORMAT=$1
case "$FORMAT" in
    freebsd)
        bash scripts/package.sh freebsd
        pkg add dist/updateself-*.pkg
        /usr/local/bin/updateself --help; /usr/local/bin/updsf --version
        /usr/local/bin/updateself --only system --dry-run
        pkg delete -y updateself
        test ! -e /usr/local/bin/updateself
        ;;
    openbsd)
        bash scripts/package.sh openbsd
        pkg_add -D unsigned dist/updateself-*.tgz
        /usr/local/bin/updateself --help; /usr/local/bin/updsf --version
        /usr/local/bin/updateself --only system --dry-run
        pkg_delete updateself
        test ! -e /usr/local/bin/updateself
        ;;
    netbsd)
        export PATH="/usr/pkg/bin:/usr/pkg/sbin:$PATH"
        bash scripts/package.sh netbsd
        pkg_add dist/updateself-*.tgz
        /usr/pkg/bin/updateself --help; /usr/pkg/bin/updsf --version
        /usr/pkg/bin/updateself --only system --dry-run
        pkg_delete updateself
        test ! -e /usr/pkg/bin/updateself
        ;;
esac
