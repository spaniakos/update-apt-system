#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
while IFS= read -r path; do bash -n "$path"; done < <(find bin scripts -type f -name '*.sh'; printf '%s\n' bin/updateself install.sh update.sh completions/updateself.bash)
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -S warning bin/updateself install.sh update.sh scripts/*.sh completions/updateself.bash
else
    echo 'ShellCheck absent; syntax checked only. CI requires ShellCheck.'
fi
python3 - <<'PY'
from pathlib import Path
import re
v=Path('VERSION').read_text().strip()
assert re.fullmatch(r'\d+\.\d+\.\d+',v)
assert f'VERSION={v}' in Path('bin/updateself').read_text()
assert f'updateself {v}' in Path('man/updateself.1').read_text()
for p in Path('.github/workflows').glob('*.yml'):
    for line in p.read_text().splitlines():
        if 'uses:' in line and './' not in line:
            assert re.search(r'@[a-f0-9]{40}(?:\s|$)',line), (p,line)
print('Version and Action pin checks passed.')
PY
