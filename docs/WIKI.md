# GitHub Wiki maintenance

The public documentation lives at <https://github.com/spaniakos/update-apt-system/wiki>.
Reviewed source documents remain here so edits can be proposed in pull requests
and each release archive retains matching documentation.

## Source and page map

| Source | Wiki page |
| --- | --- |
| docs/INSTALL.md | Installation |
| docs/CLI.md | Command-Reference |
| docs/SUPPORT.md | Platform-Support |
| docs/TROUBLESHOOTING.md | Troubleshooting |
| docs/RELEASING.md | Packages-and-Releases |
| docs/ROADMAP.md | Roadmap |
| docs/wiki/*.md | Same filename/stem |

scripts/wiki.py renders these as flat Markdown pages, rewrites document links,
validates Wiki links and generates a sidebar/footer. Each page states its version,
unreleased status and exact source revision. Change the sources rather than editing
managed Wiki pages directly: the next publication replaces managed content.
Unrelated manual pages are retained; only previously managed obsolete pages are
removed. Concurrent remote edits cause the non-force push to fail for review.

## Preview locally

```bash
python3 scripts/wiki.py build --output build/wiki --source-ref feature/updateself-v2
python3 -m unittest discover -s tests -p 'test_wiki.py' -v
```

Use a real branch/tag/commit as source-ref. Generated output is a preview, not a
claim that pages have been published. Pull requests render/validate the Wiki and
upload a wiki-preview artifact; they never receive publishing credentials.

## One-time GitHub setup

1. Enable Wikis in repository settings (already enabled for this repository).
2. If the Wiki has no pages, use GitHub's Wiki tab to create an initial **Home** page.
   GitHub requires the initial page before the Wiki Git repository can be cloned.
3. Verify Wiki Git authentication for the publisher. The workflow first uses its
   built-in GITHUB_TOKEN with contents:write. If that installation cannot write
   the Wiki, configure an appropriate Wiki-capable credential as repository Actions
   secret **WIKI_TOKEN**; it takes precedence. Do not paste credentials into issues,
   pull requests, source files or chat, and do not grant unrelated permissions.
4. Merge the reviewed documentation workflow into master. Documentation pushes to
   master publish automatically; workflow_dispatch can also publish from master.

GitHub Wiki is a separate Git repository; normal repository API writes do not
edit its pages. Missing/uninitialized Wiki or rejected authentication produces an
explicit publish-job failure. A skipped publishing job on a PR is expected.

## Manual publication with an authenticated Git client

```bash
python3 scripts/wiki.py build --output build/wiki --source-ref feature/updateself-v2
bash scripts/publish-wiki.sh build/wiki \
  https://github.com/spaniakos/update-apt-system.wiki.git feature/updateself-v2
```

This is useful for an authorized initial publication before the feature PR is
merged. Credentials stay in your Git helper/agent or ephemeral GIT_ASKPASS; the
script does not embed tokens in a remote URL or save them in a Wiki commit.

The workflow is restricted to the default branch for publishing. It neither
merges PRs nor enables new repository features or creates credentials itself.

GitHub reference: https://docs.github.com/en/communities/documenting-your-project-with-wikis/adding-or-editing-wiki-pages
