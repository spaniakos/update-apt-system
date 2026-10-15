#!/usr/bin/env bash
# Executed inside a disposable target container, never on a developer host.
set -euo pipefail
FORMAT=$1
cd /src
case "$FORMAT" in
    deb)
        apt-get update; apt-get install -y bash python3
        bash scripts/package.sh deb
        apt-get install -y ./dist/updateself_*_all.deb
        updateself --help; updsf --version; updateself --only system --dry-run
        apt-get remove -y updateself
        ;;
    rpm)
        dnf install -y bash rpm-build python3 findutils tar gzip
        bash scripts/package.sh rpm
        dnf install -y ./dist/updateself-*.noarch.rpm
        updateself --help; updsf --version; updateself --only system --dry-run
        dnf remove -y updateself
        ;;
    arch)
        pacman -Syu --noconfirm --needed base-devel python
        useradd -m builder
        chown -R builder:builder /src
        su builder -c 'cd /src && bash scripts/package.sh arch'
        pacman -U --noconfirm ./dist/updateself-*.pkg.tar.zst
        updateself --help; updsf --version; updateself --only system --dry-run
        pacman -R --noconfirm updateself
        ;;
    apk)
        apk add bash alpine-sdk python3 sudo
        adduser -D builder
        addgroup builder abuild
        printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/builder
        chown -R builder:builder /src
        su builder -c 'abuild-keygen -a -n; cd /src; bash scripts/package.sh apk'
        # Ephemeral CI key only: do not install it on users' systems.
        cp /home/builder/.abuild/*.pub /etc/apk/keys/
        apk add ./dist/updateself-*.apk
        updateself --help; updsf --version; updateself --only system --dry-run
        apk del updateself
        ;;
    xbps)
        xbps-install -Suy xbps
        xbps-install -Suy bash python3 tar gzip
        bash scripts/package.sh xbps
        xbps-rindex -a dist/*.xbps
        xbps-install -y --repository="$PWD/dist" updateself
        updateself --help; updsf --version; updateself --only system --dry-run
        xbps-remove -y updateself
        ;;
    slackware)
        bash scripts/package.sh slackware
        installpkg dist/updateself-*.txz
        updateself --help; updsf --version; updateself --only system --dry-run
        removepkg updateself
        ;;
    *) exit 2 ;;
esac
[ ! -e /usr/bin/updateself ] && [ ! -L /usr/bin/updsf ]
echo "Native package installation/removal passed: $FORMAT"
