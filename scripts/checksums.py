#!/usr/bin/env python3
"""Hash release assets in stable filename order; no platform-specific hash CLI."""
import hashlib
from pathlib import Path
import sys
root = Path(sys.argv[1] if len(sys.argv) > 1 else "dist")
with (root / "SHA256SUMS").open("w") as out:
    for path in sorted(root.iterdir()):
        if path.is_file() and path.name != "SHA256SUMS":
            out.write(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n")
