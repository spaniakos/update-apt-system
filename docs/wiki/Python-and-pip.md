# Python and pip

Discovery is read-only. The updater inspects PATH interpreters and common
versioned command names, reporting their path, versions, externally-managed marker
and virtualenv state. It does not scan disks or bootstrap missing pip.

```bash
updateself --only python
updateself --only python --venv "$HOME/venvs/cli" --dry-run
updateself --only python --venv "$HOME/venvs/cli" --ask
updateself --only python --python "$HOME/.pyenv/versions/3.13.0/bin/python" --ask
```

Replace the example paths/version with your existing installation. --python and
--venv can be repeated; use absolute paths. Updates run through the selected
interpreter's -m pip, not an unrelated pip executable.

| Installation | Owner/update path |
| --- | --- |
| Distribution/Homebrew Python and pip | Native package manager |
| Recognised user-owned standalone Python | Explicit --python pip update |
| Explicit virtual environment | --venv pip update |
| pipx/uv CLI applications | Their respective components |
| Conda-managed interpreter/environment | Environment manager; not automated here |

System Python is not user-owned just because it lacks a marker. A selected
non-venv interpreter must resolve inside the user's home and outside known
managed layouts. No sudo pip or --break-system-packages is used.

## Bulk packages are a separate opt-in

```bash
updateself --only python --venv "$HOME/venvs/cli" --python-packages --ask
```

This updates pip-listed packages in explicit environments only. It can cross
major versions and does not apply unprovided project constraints. It does not
update every discovered interpreter's global packages. See [[Troubleshooting]]
and [[Supported Tools|Supported-Tools]].
