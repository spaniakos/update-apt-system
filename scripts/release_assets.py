#!/usr/bin/env python3
"""Validate the full package matrix and assemble assets without publishing."""
import argparse
import hashlib
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {
    "deb": ["updateself_*.deb"],
    "rpm": ["updateself-*.noarch.rpm", "updateself-*.src.rpm"],
    "arch": ["updateself-*.pkg.tar.zst"],
    "apk": ["updateself-*.apk"],
    "xbps": ["updateself-*.xbps"],
    "slackware": ["updateself-*.txz"],
    "macos-macos-15-intel": ["updateself-*-macos-x86_64.pkg"],
    "macos-macos-15": ["updateself-*-macos-arm64.pkg"],
    "freebsd": ["updateself-*-freebsd-*.pkg"],
    "openbsd": ["updateself-*.tgz"],
    "netbsd": ["updateself-*-netbsd-*.tgz"],
    "nix": ["flake.nix", "flake.lock", "nix-build.json"],
    "portable-recipes": ["updateself-*.tar.gz", "updateself.rb", "Portfile", "updateself-*.ebuild"],
}


def assemble(source, output, revision):
    source, output = Path(source), Path(output)
    if not re.fullmatch(r"[a-f0-9]{40}", revision):
        raise ValueError("An exact source commit SHA is required")
    if output.is_symlink() or (output.exists() and any(output.iterdir())):
        raise ValueError("Choose an empty output directory")
    assets = {}
    for name, patterns in REQUIRED.items():
        directory = source / ("package-" + name)
        if directory.is_symlink() or not directory.is_dir():
            raise ValueError(f"Missing package bundle: {name}")
        for path in directory.rglob("*"):
            if path.is_symlink():
                raise ValueError(f"Symlink asset: {path}")
            if not path.is_file() or path.name == "SHA256SUMS":
                continue
            if path.stat().st_size == 0:
                raise ValueError(f"Empty asset: {path}")
            if not re.fullmatch(r"[A-Za-z0-9_.+-]+", path.name):
                raise ValueError(f"Unsafe asset filename: {path.name}")
            if path.name in assets or path.name in {"RELEASE-NOTES.md", "BUILD-REPORT.md"}:
                raise ValueError(f"Duplicate/reserved asset filename: {path.name}")
            assets[path.name] = path
        for pattern in patterns:
            if not any(p.is_file() for p in directory.glob(pattern)):
                raise ValueError(f"Missing {name} asset matching {pattern}")
    version = (ROOT / "VERSION").read_text().strip()
    notes = (ROOT / f"docs/releases/{version}.md").read_text()
    output.mkdir(parents=True, exist_ok=True)
    for name, path in assets.items():
        shutil.copyfile(path, output / name)
    (output / "RELEASE-NOTES.md").write_text(notes)
    report = [f"# updateself {version} build report", "", f"Source commit: `{revision}`", "",
              "All required package bundles were collected after the CI build and installation checks passed.",
              "Nix output contains source recipes and store metadata, not a portable binary package.",
              "macOS installers are unsigned; Alpine uses an ephemeral CI test key. See release notes.", "",
              "| Bundle | Required assets |", "| --- | --- |"]
    report.extend(f"| {name} | {', '.join(patterns)} |" for name, patterns in REQUIRED.items())
    (output / "BUILD-REPORT.md").write_text("\n".join(report) + "\n")
    with (output / "SHA256SUMS").open("w") as sums:
        for path in sorted(output.iterdir()):
            if path.name != "SHA256SUMS":
                sums.write(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n")
    return len(assets)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--revision", required=True)
    args = parser.parse_args()
    print(f"Assembled {assemble(args.source, args.output, args.revision)} package assets with notes and checksums")
