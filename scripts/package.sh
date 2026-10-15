#!/usr/bin/env bash
# Native package generation. Run in an isolated builder of the target OS.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
FORMAT=${1:-portable}
VERSION=$(cat "$ROOT/VERSION")
OUT=${OUT:-$ROOT/dist}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/updateself-package.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
PREFIX=/usr
case "$FORMAT" in freebsd|openbsd|macos) PREFIX=/usr/local ;; netbsd) PREFIX=/usr/pkg ;; esac
bash "$ROOT/install.sh" --system --prefix "$PREFIX" --destdir "$WORK/root"
# Native packages own their files via the package database, not the Git installer.
rm "$WORK/root$PREFIX/share/updateself/manifest"
DESCRIPTION='Cross-platform operating-system and CLI tool updater'
URL=https://github.com/spaniakos/update-apt-system
case "$FORMAT" in
    portable)
        mkdir "$WORK/updateself-$VERSION"
        for item in bin docs completions man scripts packaging tests .github flake.nix install.sh update.sh Makefile README.md VERSION LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md; do
            cp -R "$ROOT/$item" "$WORK/updateself-$VERSION/"
        done
        tar -czf "$OUT/updateself-$VERSION.tar.gz" -C "$WORK" "updateself-$VERSION"
        # Source contains packaging/build inputs as well as the executable.
        ;;
    deb)
        mkdir "$WORK/root/DEBIAN"
        cat > "$WORK/root/DEBIAN/control" <<EOF
Package: updateself
Version: $VERSION-1
Section: admin
Priority: optional
Architecture: all
Maintainer: Georgios Spanos <spaniakos@gmail.com>
Depends: bash (>= 3.2), coreutils
Homepage: $URL
Description: $DESCRIPTION
 Updates installed packages and supported user-owned tools.
EOF
        mkdir -p "$WORK/root/usr/share/doc/updateself"
        cp "$ROOT/LICENSE" "$WORK/root/usr/share/doc/updateself/copyright"
        dpkg-deb --root-owner-group --build "$WORK/root" "$OUT/updateself_${VERSION}-1_all.deb"
        ;;
    rpm)
        mkdir -p "$WORK/rpm/BUILD" "$WORK/rpm/RPMS" "$WORK/rpm/SOURCES" "$WORK/rpm/SPECS" "$WORK/rpm/SRPMS"
        tar -czf "$WORK/rpm/SOURCES/payload.tar.gz" -C "$WORK/root" .
        cat > "$WORK/rpm/SPECS/updateself.spec" <<EOF
Name: updateself
Version: $VERSION
Release: 1%{?dist}
Summary: $DESCRIPTION
License: GPL-3.0-only
URL: $URL
Source0: payload.tar.gz
BuildArch: noarch
Requires: bash >= 3.2
%description
$DESCRIPTION
%prep
%build
%install
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}
%files
/usr/bin/updateself
/usr/bin/updsf
/usr/share/man/man1/*
/usr/share/bash-completion/completions/updateself
/usr/share/zsh/site-functions/_updateself
%dir /usr/share/updateself
%license /usr/share/updateself/LICENSE
%doc /usr/share/updateself/README.md
EOF
        rpmbuild --define "_topdir $WORK/rpm" -ba "$WORK/rpm/SPECS/updateself.spec"
        find "$WORK/rpm/RPMS" "$WORK/rpm/SRPMS" -name '*.rpm' -exec cp {} "$OUT/" \;
        ;;
    arch)
        # makepkg deliberately refuses root.
        tar -czf "$WORK/payload.tar.gz" -C "$WORK/root" .
        sum=$(sha256sum "$WORK/payload.tar.gz" | cut -d' ' -f1)
        cat > "$WORK/PKGBUILD" <<EOF
pkgname=updateself
pkgver=$VERSION
pkgrel=1
pkgdesc='$DESCRIPTION'
arch=('any')
url='$URL'
license=('GPL-3.0-only')
depends=('bash')
source=('payload.tar.gz')
sha256sums=('$sum')
package() {
  tar -xzf "\$srcdir/payload.tar.gz" -C "\$pkgdir"
}
EOF
        (cd "$WORK"; makepkg --nodeps --noconfirm)
        find "$WORK" -maxdepth 1 -name '*.pkg.tar.*' -exec cp {} "$OUT/" \;
        ;;
    apk)
        tar -czf "$WORK/payload.tar.gz" -C "$WORK/root" .
        sum=$(sha512sum "$WORK/payload.tar.gz" | cut -d' ' -f1)
        cat > "$WORK/APKBUILD" <<EOF
pkgname=updateself
pkgver=$VERSION
pkgrel=0
pkgdesc='$DESCRIPTION'
url='$URL'
arch='noarch'
license='GPL-3.0-only'
depends='bash'
options='!check'
source='payload.tar.gz'
package() {
  mkdir -p "\$pkgdir"
  tar -xzf "\$srcdir/payload.tar.gz" -C "\$pkgdir"
}
sha512sums='$sum  payload.tar.gz'
EOF
        (cd "$WORK"; REPODEST="$WORK/packages" abuild -r)
        find "$WORK/packages" -name 'updateself-*.apk' -exec cp {} "$OUT/" \;
        ;;
    xbps)
        (cd "$OUT"; xbps-create -A noarch -n "updateself-${VERSION}_1" -s "$DESCRIPTION" -l GPL-3.0-only -m 'Georgios Spanos <spaniakos@gmail.com>' -D bash "$WORK/root")
        ;;
    slackware)
        mkdir -p "$WORK/root/install"
        for i in 1 2 3 4 5 6 7 8 9 10 11; do
            if [ "$i" -eq 1 ]; then printf 'updateself: %s\n' "$DESCRIPTION"; else printf 'updateself:\n'; fi
        done > "$WORK/root/install/slack-desc"
        printf 'bash\n' > "$WORK/root/install/slack-required"
        (cd "$WORK/root"; makepkg -l y -c n "$OUT/updateself-$VERSION-noarch-1.txz")
        ;;
    macos)
        pkgbuild --root "$WORK/root" --identifier gr.makeasite.updateself --version "$VERSION" --install-location / "$OUT/updateself-$VERSION-macos-$(uname -m).pkg"
        ;;
    freebsd)
        # pkg manifest embeds all files/links; no dependence on legacy plist parsing.
        python3 "$ROOT/scripts/freebsd-manifest.py" "$WORK/root" "$VERSION" > "$WORK/manifest.json"
        pkg create -r "$WORK/root" -M "$WORK/manifest.json" -o "$WORK"
        for p in "$WORK"/updateself-*.pkg; do cp "$p" "$OUT/updateself-$VERSION-freebsd-$(uname -r)-$(uname -m).pkg"; done
        ;;
    openbsd)
        (cd "$WORK/root$PREFIX"; find . -type f -o -type l | sed 's|^./||' | sort) > "$WORK/PLIST"
        printf '%s\n' "$DESCRIPTION" > "$WORK/DESCR"
        bashpkg=$(pkg_info -e 'bash-*' | head -n 1)
        [ -n "$bashpkg" ] || { echo 'Bash package required' >&2; exit 1; }
        pkg_create -A '*' -B "$WORK/root" -p "$PREFIX" -f "$WORK/PLIST" -d "$WORK/DESCR" \
            -D "COMMENT=$DESCRIPTION" -D FULLPKGPATH=sysutils/updateself -D PORTSDIR=/usr/ports \
            -P "shells/bash:bash-*:bash" "$OUT/updateself-$VERSION-openbsd-$(uname -r)-$(uname -m).tgz"
        ;;
    netbsd)
        (cd "$WORK/root$PREFIX"; find . -type f -o -type l | sed 's|^./||' | sort) > "$WORK/PLIST"
        printf '%s\n' "$DESCRIPTION" > "$WORK/COMMENT"
        printf '%s\n' "$DESCRIPTION" > "$WORK/DESCR"
        printf 'OPSYS=NetBSD\nOS_VERSION=%s\nMACHINE_ARCH=%s\nPKGPATH=sysutils/updateself\nHOMEPAGE=%s\nLICENSE=gnu-gpl-v3\n' "$(uname -r)" "$(uname -p)" "$URL" > "$WORK/BUILD_INFO"
        pkg_create -p "$WORK/root$PREFIX" -I "$PREFIX" -u root -g wheel -P 'bash>=3.2' -B "$WORK/BUILD_INFO" \
            -c "$WORK/COMMENT" -d "$WORK/DESCR" -f "$WORK/PLIST" "$OUT/updateself-$VERSION-netbsd-$(uname -r)-$(uname -m).tgz"
        ;;
    *) echo "Unknown format: $FORMAT" >&2; exit 2 ;;
esac
printf 'Built %s for %s in %s\n' "$VERSION" "$FORMAT" "$OUT"
