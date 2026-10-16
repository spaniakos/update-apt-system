#!/usr/bin/env python3
"""Keep the Bash executable standalone; --check verifies the embedded source."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
path = root / "bin/updateself"
start, end = "# BEGIN EMBEDDED LIFECYCLE\n", "# END EMBEDDED LIFECYCLE\n"
text = path.read_text()
before, rest = text.split(start, 1)
_, after = rest.split(end, 1)
result = before + start + (root / "src/lifecycle.bash").read_text() + end + after
if "--check" in sys.argv:
    if text != result:
        raise SystemExit("Run python3 scripts/embed-lifecycle.py before committing")
else:
    path.write_text(result)
