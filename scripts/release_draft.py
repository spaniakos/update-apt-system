#!/usr/bin/env python3
"""Validate release requests and populate a draft using GitHub CLI authentication."""
import argparse
from datetime import date
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]


class APIError(RuntimeError):
    def __init__(self, status, detail):
        super().__init__(f"GitHub API failed ({status}): {detail}")
        self.status = status


class GitHub:
    def __init__(self, repository):
        if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
            raise ValueError("Expected OWNER/REPOSITORY")
        self.base = f"repos/{repository}"
        self.repository = repository

    def api(self, path, method="GET", payload=None):
        command = ["gh", "api", "--include", "--method", method, f"{self.base}/{path}"]
        if payload is not None:
            command.extend(["--input", "-"])
        result = subprocess.run(command, input=json.dumps(payload) if payload is not None else None,
                                text=True, capture_output=True)
        status = re.search(r"^HTTP/\S+ (\d{3})", result.stdout, re.M)
        code = int(status.group(1)) if status else 0
        if result.returncode:
            raise APIError(code, result.stderr.strip())
        parts = re.split(r"\r?\n\r?\n", result.stdout, maxsplit=1)
        return json.loads(parts[-1])

    def upload(self, tag, assets):
        # Only called after checking draft=true; never replace published assets.
        subprocess.run(["gh", "release", "upload", tag, *map(str, assets),
                        "--repo", self.repository, "--clobber"], check=True)


def validate_request(event, ref, mode, tag):
    version = (ROOT / "VERSION").read_text().strip()
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("VERSION must contain X.Y.Z")
    if event == "workflow_dispatch" and mode == "preview":
        return False, ""
    expected = "v" + version
    if event == "workflow_dispatch":
        if mode != "create-draft" or ref != "refs/heads/master":
            raise ValueError("Create-draft requests must run from master")
        if tag != expected:
            raise ValueError(f"Enter release tag {expected}, matching VERSION")
    elif event == "push" and ref == f"refs/tags/{expected}":
        tag = expected
    else:
        raise ValueError("Release reference must match VERSION")
    heading = re.search(rf"^## {re.escape(version)} — (\d{{4}}-\d{{2}}-\d{{2}})$",
                        (ROOT / "CHANGELOG.md").read_text(), re.M)
    if not heading:
        raise ValueError("Finalize the CHANGELOG release date before creating a draft")
    date.fromisoformat(heading.group(1))
    if not (ROOT / f"docs/releases/{version}.md").is_file():
        raise ValueError("Release notes are missing")
    return True, tag


def find_release(client, tag):
    matches = []
    page = 1
    while True:
        releases = client.api(f"releases?per_page=100&page={page}")
        matches.extend(r for r in releases if r["tag_name"] == tag)
        if len(releases) < 100:
            break
        page += 1
    if len(matches) > 1:
        raise ValueError("Multiple releases use this tag; resolve them before retrying")
    if matches and not matches[0]["draft"]:
        raise ValueError("This release is already published; its notes and assets will not be changed")
    return matches[0] if matches else None


def populate(client, tag, revision, directory):
    if not re.fullmatch(r"v\d+\.\d+\.\d+", tag) or not re.fullmatch(r"[a-f0-9]{40}", revision):
        raise ValueError("Expected a version tag and exact commit SHA")
    directory = Path(directory)
    assets = sorted(directory.iterdir())
    if not assets or any(p.is_symlink() or not p.is_file() for p in assets):
        raise ValueError("Release assets must be regular files")
    notes = (directory / "RELEASE-NOTES.md").read_text()
    release = find_release(client, tag)
    try:
        target = client.api("git/ref/tags/" + quote(tag, safe=""))["object"]
    except APIError as error:
        if error.status != 404:
            raise
        target = None
    if target:
        # Follow annotated tags, but never move or replace an existing tag.
        for _ in range(10):
            if target["type"] != "tag":
                break
            target = client.api("git/tags/" + target["sha"])["object"]
        if target["type"] != "commit" or target["sha"] != revision:
            raise ValueError("Existing tag points to a different commit; refusing to move it")
    else:
        if release and release.get("target_commitish") not in {"master", revision}:
            raise ValueError("Saved draft targets another revision; select master before retrying")
        client.api("git/refs", "POST", {"ref": "refs/tags/" + tag, "sha": revision})
    if not release:
        release = client.api("releases", "POST", {"tag_name": tag, "target_commitish": revision,
                             "name": "updateself " + tag, "body": notes, "draft": True})
    # Recheck state immediately before upload; no edit of title, body or draft flag.
    current = client.api(f"releases/{release['id']}")
    if not current["draft"]:
        raise ValueError("Release was published during the build; refusing to upload")
    client.upload(tag, assets)
    return current["html_url"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["validate", "populate"])
    parser.add_argument("--tag", default="")
    parser.add_argument("--revision")
    parser.add_argument("--directory", default="dist")
    args = parser.parse_args()
    if args.command == "validate":
        enabled, tag = validate_request(os.environ["GITHUB_EVENT_NAME"], os.environ["GITHUB_REF"],
                                        os.environ.get("RELEASE_MODE", "preview"),
                                        os.environ.get("REQUESTED_TAG", ""))
        with open(os.environ["GITHUB_OUTPUT"], "a") as output:
            output.write(f"enabled={str(enabled).lower()}\ntag={tag}\n")
        print(f"Release mode: {'draft ' + tag if enabled else 'preview only'}")
    else:
        print(populate(GitHub(os.environ["GITHUB_REPOSITORY"]), args.tag, args.revision, args.directory))


if __name__ == "__main__":
    main()
