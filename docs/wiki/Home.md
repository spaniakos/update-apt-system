# updateself documentation

**updateself** updates installed system packages and common CLI tools.
**updsf** invokes the same program; update.sh remains available from a checkout.

## First run

```bash
bash update.sh --help
bash update.sh --dry-run
bash update.sh --ask
```

The default skips confirmations. Start with a preview, then review commands with
--ask. Authentication and vendor prompts can still occur. No reboot is initiated.

## Guides

| Task | Guide |
| --- | --- |
| Install, upgrade, remove or enable completions | [[Installation]] |
| Select options and components | [Command Reference](https://github.com/spaniakos/update-apt-system/wiki/Command-Reference) |
| Update your platform | [[macOS]], [[Linux]], [[BSD]], [[Nix]] |
| Understand tool ownership | [Supported Tools](https://github.com/spaniakos/update-apt-system/wiki/Supported-Tools) |
| Inspect Python and update pip | [Python and pip](https://github.com/spaniakos/update-apt-system/wiki/Python-and-pip) |
| Download packages or understand CI | [Packages and Releases](https://github.com/spaniakos/update-apt-system/wiki/Packages-and-Releases) |
| Check compatibility and limitations | [Platform Support](https://github.com/spaniakos/update-apt-system/wiki/Platform-Support) |
| Resolve failures or skipped tools | [[Troubleshooting]] and [[FAQ]] |
| See future work | [[Roadmap]] |

Missing tools are skipped, never installed. Package-managed executables stay
with their owner. User tools run under the selected account. Cleanup, supported
base-system installation and bulk Python updates require explicit options.

Source, contribution instructions and issue reporting live in the
[project repository](https://github.com/spaniakos/update-apt-system).
