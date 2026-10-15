#!/usr/bin/env bash
# Requires an initialized Wiki and normal Git authentication (or GIT_ASKPASS).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[ "$#" -ge 2 ] || { echo 'Usage: publish-wiki.sh GENERATED_DIRECTORY WIKI_GIT_URL [SOURCE_REF]' >&2; exit 2; }
SOURCE=$(cd "$1" && pwd)
REMOTE=$2
SOURCE_REF=${3:-reviewed-source}
case "$REMOTE" in https://*@*|http://*@*) echo 'Use a credential helper/askpass, not credentials in URLs.' >&2; exit 2 ;; esac
[ -f "$SOURCE/Home.md" ] || { echo 'Render the Wiki first; Home.md is required.' >&2; exit 2; }
WORK=$(mktemp -d "${TMPDIR:-/tmp}/updateself-wiki.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
if ! GIT_TERMINAL_PROMPT=0 git clone --quiet "$REMOTE" "$WORK/wiki"; then
    echo 'Cannot clone the Wiki. Create its initial Home page in GitHub and check Wiki Git authentication. See docs/WIKI.md.' >&2
    exit 1
fi
git -C "$WORK/wiki" rev-parse --verify HEAD >/dev/null || { echo 'Wiki must have an initial page/commit.' >&2; exit 1; }
python3 "$ROOT/scripts/wiki.py" sync --source "$SOURCE" --checkout "$WORK/wiki"
# The clone starts clean; sync only changed the managed manifest/pages.
git -C "$WORK/wiki" add --all
if git -C "$WORK/wiki" diff --cached --quiet; then echo 'Wiki is already current.'; exit 0; fi
git -C "$WORK/wiki" -c user.name='updateself documentation' -c user.email='github-actions[bot]@users.noreply.github.com' \
    commit --quiet -m "Publish updateself documentation from $SOURCE_REF"
# No force: concurrent manual edits must be fetched/reviewed rather than overwritten.
git -C "$WORK/wiki" push --quiet origin HEAD
echo 'GitHub Wiki published.'
