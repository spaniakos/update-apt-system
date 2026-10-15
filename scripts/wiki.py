#!/usr/bin/env python3
"""Render versioned sources as GitHub Wiki pages; reconcile only managed files."""
import argparse
import json
from pathlib import Path
import posixpath
import re
import shutil
from urllib.parse import quote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
IMPORTED = {
    "Installation": "docs/INSTALL.md",
    "Command-Reference": "docs/CLI.md",
    "Platform-Support": "docs/SUPPORT.md",
    "Troubleshooting": "docs/TROUBLESHOOTING.md",
    "Packages-and-Releases": "docs/RELEASING.md",
    "Roadmap": "docs/ROADMAP.md",
}
MANIFEST = ".updateself-managed-pages.json"
PAGE = re.compile(r"[A-Za-z0-9_-]+\.md\Z")
WIKILINK = re.compile(r"\[\[([^\]\n]+)\]\]")
MARKDOWN_LINK = re.compile(r"(?<!!)\[([^\]\n]+)\]\(([^\s)]+)\)")


def rewrite_links(text, source, page_sources, repository, source_ref):
    by_source = {str(path): slug for slug, path in page_sources.items()}
    def replace(match):
        label, target = match.groups()
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            return match.group(0)
        path = posixpath.normpath(posixpath.join(posixpath.dirname(str(source)), parsed.path))
        if path.startswith("../") or path.startswith("/") or not (ROOT / path).exists():
            raise ValueError(f"Unresolved source link in {source}: {target}")
        suffix = ("#" + parsed.fragment) if parsed.fragment else ""
        if path in by_source:
            url = f"https://github.com/{repository}/wiki/{by_source[path]}{suffix}"
        else:
            url = f"https://github.com/{repository}/blob/{quote(source_ref, safe='')}/{quote(path, safe='/')}{suffix}"
        return f"[{label}]({url})"
    return MARKDOWN_LINK.sub(replace, text)


def build(output, source_ref, repository="spaniakos/update-apt-system"):
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise ValueError("Repository must be OWNER/NAME")
    page_sources = {slug: Path(path) for slug, path in IMPORTED.items()}
    page_sources.update({p.stem: p.relative_to(ROOT) for p in (ROOT / "docs/wiki").glob("*.md")})
    version = (ROOT / "VERSION").read_text().strip()
    unreleased = re.search(rf"^## {re.escape(version)}.*unreleased", (ROOT / "CHANGELOG.md").read_text(), re.M)
    status = " (unreleased)" if unreleased else ""
    header = f"> Documentation for **updateself {version}{status}**. [Versioned source](https://github.com/{repository}/tree/{quote(source_ref, safe='')}).\n\n"
    rendered = {}
    for slug, path in page_sources.items():
        body = (ROOT / path).read_text()
        for match in WIKILINK.finditer(body):
            target = match.group(1).rsplit("|", 1)[-1].split("#", 1)[0]
            if target not in page_sources:
                raise ValueError(f"Unknown Wiki target in {path}: {target}")
        rendered[slug + ".md"] = header + rewrite_links(body, path, page_sources, repository, source_ref)
    rendered["_Sidebar.md"] = "\n".join([
        "**updateself**", "", "[[Home]]", "[[Installation]]",
        "[[Command reference|Command-Reference]]", "", "**Platform guides**", "",
        "[[macOS]]", "[[Linux]]", "[[BSD]]", "[[Nix]]", "",
        "**Tools and help**", "", "[[Supported tools|Supported-Tools]]",
        "[[Python and pip|Python-and-pip]]", "[[Platform support|Platform-Support]]",
        "[[Troubleshooting]]", "[[FAQ]]", "", "**Project**", "",
        "[[Packages and releases|Packages-and-Releases]]", "[[Roadmap]]", "",
    ])
    rendered["_Footer.md"] = (
        f"updateself **{version}{status}** · [[Home]] · [[Command reference|Command-Reference]] · "
        f"[Edit documentation sources](https://github.com/{repository}/tree/{quote(source_ref, safe='')}/docs)\n"
    )
    # Compute/validate everything before writing any output.
    output = Path(output)
    if output.is_symlink():
        raise ValueError("Output directory must not be a symlink")
    previous = []
    output_manifest = output / MANIFEST
    if output.exists() and any(output.iterdir()):
        if not output_manifest.is_file() or output_manifest.is_symlink():
            raise ValueError("Choose an empty output directory or an existing generated Wiki directory")
        previous = json.loads(output_manifest.read_text())
        if not isinstance(previous, list) or any(not isinstance(n, str) or not PAGE.fullmatch(n) for n in previous):
            raise ValueError("Invalid generated-page manifest")
        if any(p.name not in set(previous + [MANIFEST]) for p in output.iterdir()):
            raise ValueError("Output contains files not owned by the Wiki renderer")
    for name in set(previous) | set(rendered):
        if (output / name).is_symlink():
            raise ValueError(f"Output must not be a symlink: {output / name}")
    output.mkdir(parents=True, exist_ok=True)
    for name in set(previous) - set(rendered):
        (output / name).unlink(missing_ok=True)
    for name, body in rendered.items():
        target = output / name
        if target.is_symlink():
            raise ValueError(f"Output must not be a symlink: {target}")
        target.write_text(body)
    output_manifest.write_text(json.dumps(sorted(rendered), indent=2) + "\n")
    return sorted(rendered)


def reconcile(source, checkout):
    """Preserve manual pages and remove only obsolete, previously managed pages."""
    source, checkout = Path(source), Path(checkout)
    if not (checkout / ".git").exists():
        raise ValueError("Destination must be an existing Wiki Git checkout")
    files = sorted(p.name for p in source.glob("*.md"))
    if "Home.md" not in files or any(not PAGE.fullmatch(n) for n in files):
        raise ValueError("Generated pages need Home.md and safe flat Markdown filenames")
    manifest = checkout / MANIFEST
    if manifest.is_symlink():
        raise ValueError("Managed-page manifest cannot be a symlink")
    previous = json.loads(manifest.read_text()) if manifest.exists() else []
    if not isinstance(previous, list) or any(not isinstance(n, str) or not PAGE.fullmatch(n) for n in previous):
        raise ValueError("Invalid managed-page manifest")
    for name in set(previous + files):
        if (checkout / name).is_symlink() or (source / name).is_symlink():
            raise ValueError(f"Refusing symlink page: {name}")
    for name in set(previous) - set(files):
        (checkout / name).unlink(missing_ok=True)
    for name in files:
        shutil.copyfile(source / name, checkout / name)
    manifest.write_text(json.dumps(files, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    render = commands.add_parser("build")
    render.add_argument("--output", required=True)
    render.add_argument("--source-ref", required=True)
    render.add_argument("--repository", default="spaniakos/update-apt-system")
    sync = commands.add_parser("sync")
    sync.add_argument("--source", required=True)
    sync.add_argument("--checkout", required=True)
    args = parser.parse_args()
    if args.command == "build":
        names = build(args.output, args.source_ref, args.repository)
        print(f"Rendered and validated {len(names)} Wiki files in {args.output}")
    else:
        reconcile(args.source, args.checkout)
        print("Synchronized managed Wiki pages; unrelated pages retained")


if __name__ == "__main__":
    main()
