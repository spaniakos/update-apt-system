#!/usr/bin/env python3
"""Generate release-specific source recipes; does not submit them anywhere."""
import hashlib
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1] if len(sys.argv) > 1 else root / "dist")
v = (root / "VERSION").read_text().strip()
archive = out / f"updateself-{v}.tar.gz"
sha = hashlib.sha256(archive.read_bytes()).hexdigest()
sha512 = hashlib.sha512(archive.read_bytes()).hexdigest()
url = f"https://github.com/spaniakos/updateself/releases/download/v{v}/updateself-{v}.tar.gz"
(out / "updateself.rb").write_text(f'''class Updateself < Formula
  desc "Cross-platform operating-system and CLI tool updater"
  homepage "https://github.com/spaniakos/updateself"
  url "{url}"
  sha256 "{sha}"
  license "GPL-3.0-only"
  def install
    bin.install "bin/updateself"
    bin.install_symlink "updateself" => "updsf"
    man1.install "man/updateself.1", "man/updsf.1"
    bash_completion.install "completions/updateself.bash" => "updateself"
    zsh_completion.install "completions/_updateself"
    doc.install "README.md", "CHANGELOG.md"
  end
  test do
    assert_match "{v}", shell_output("#{{bin}}/updateself --version")
    assert_match "Usage:", shell_output("#{{bin}}/updsf --help")
  end
end
''')
(out / "Portfile").write_text(f'''PortSystem 1.0
name updateself
version {v}
categories sysutils
platforms any
supported_archs noarch
license GPL-3
maintainers nomaintainer
description Cross-platform operating-system and CLI tool updater
long_description ${{description}}
homepage https://github.com/spaniakos/updateself
master_sites https://github.com/spaniakos/updateself/releases/download/v${{version}}
checksums sha256 {sha} size {archive.stat().st_size}
depends_run port:bash
use_configure no
build {{}}
destroot {{
    system -W ${{worksrcpath}} "bash install.sh --system --prefix ${{prefix}} --destdir ${{destroot}}"
    delete ${{destroot}}${{prefix}}/share/updateself/manifest
}}
''')
(out / f"updateself-{v}.ebuild").write_text(f'''EAPI=8
DESCRIPTION="Cross-platform operating-system and CLI tool updater"
HOMEPAGE="https://github.com/spaniakos/updateself"
SRC_URI="{url}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RDEPEND=">=app-shells/bash-3.2"
src_compile() {{ :; }}
src_install() {{
    bash install.sh --system --prefix /usr --destdir "${{D}}" || die
    rm "${{D}}/usr/share/updateself/manifest" || die
}}
''')
(out / "updateself-source.sha512").write_text(f"{sha512}  {archive.name}\n")
