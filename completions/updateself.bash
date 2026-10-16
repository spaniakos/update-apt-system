# Source this file for interactive Bash completion (Bash 3.2+).
_updateself_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=()
    while IFS= read -r item; do COMPREPLY+=("$item"); done < <(compgen -W '--help --version --yes --ask --user --dry-run --check-self-update --self-update --uninstall --only --skip --include --cleanup --full-upgrade --base-install --apple-install --greedy --python --venv --python-packages --nix-config --nix-flake --nix-update-inputs --log --no-color --list-components' -- "$cur")
}
complete -F _updateself_complete updateself updsf
