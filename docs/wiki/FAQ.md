# Frequently asked questions

## Does it run automatically?

The default skips script/package confirmations. --ask confirms commands;
--dry-run previews them. Authentication and some vendor prompts can remain.

## Is -n dry-run?

No: -n retains the original meaning, ask. Use --dry-run.
Both -h/--help and -v/--version work.

## Does it update every user and Python environment?

No. User operations target one account. Python discovery is read-only until
--python or --venv selects an environment. See [[Python and pip|Python-and-pip]].

## Why is an installed tool skipped?

It may belong to another manager, need an absent helper or have uncertain
ownership. Check the printed reason and [[Supported Tools|Supported-Tools]].

## Will it remove packages or reboot?

Cleanup is opt-in. APT dist-upgrade needs --full-upgrade. Native dependency
resolution can still replace/remove packages, and package hooks can restart
services. No reboot is initiated. Supported base installation and declarative
activation require explicit flags.

## Does OK mean packages changed?

It means the command completed. Native output distinguishes updates from an
already-current state; no changed-package count is invented.

## Where are downloads?

CI artifacts belong to workflow runs. Tags prepare draft releases; only
published releases are public downloads. See [[Packages and Releases|Packages-and-Releases]].

## Where do documentation edits go?

Edit the project's reviewed source documents. Managed Wiki pages are generated
and can be overwritten by publication; unrelated manual pages are preserved.
See [Wiki maintenance](../../docs/WIKI.md).
