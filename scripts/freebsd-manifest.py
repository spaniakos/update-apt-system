#!/usr/bin/env python3
"""Emit a pkg manifest for exactly the staged runtime files."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1])
files = {}
for path in sorted(root.rglob("*")):
    if path.is_file() or path.is_symlink():
        files["/" + path.relative_to(root).as_posix()] = "-"
print(json.dumps({
    "name": "updateself", "version": sys.argv[2], "origin": "sysutils/updateself",
    "comment": "Cross-platform operating-system and CLI tool updater",
    "desc": "Update installed packages and supported user-owned tools.",
    "maintainer": "spaniakos@gmail.com", "www": "https://github.com/spaniakos/update-apt-system",
    "prefix": "/usr/local", "arch": subprocess.check_output(["pkg", "config", "ABI"], text=True).strip(),
    "licenses": ["GPLv3"], "licenselogic": "single", "files": files,
    "deps": {"bash": {"origin": "shells/bash", "version": subprocess.check_output(["pkg", "query", "%v", "bash"], text=True).strip()}},
}))
