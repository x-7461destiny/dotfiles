#!/usr/bin/env bash
set -Eeuo pipefail

DRY_RUN=false
BACKUP_EXISTING=false

usage() {
    cat <<'EOF'
Usage: install_linux.sh [--dry-run] [--backup-existing]

  --dry-run          Print planned operations without changing files.
  --backup-existing  Move conflicting targets to timestamped backups.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --backup-existing) BACKUP_EXISTING=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"

run() {
    if $DRY_RUN; then
        printf 'DRY-RUN:'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

same_link() {
    local src=$1
    local dest=$2
    [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]
}

assert_linkable() {
    local src=$1
    local dest=$2

    [[ -e "$src" ]] || { echo "Source does not exist: $src" >&2; return 1; }
    if [[ ! -e "$dest" && ! -L "$dest" ]] || same_link "$src" "$dest"; then
        return
    fi

    if ! $BACKUP_EXISTING; then
        echo "Target already exists: $dest" >&2
        echo "Re-run with --backup-existing to move it aside safely." >&2
        return 1
    fi

    local backup="${dest}.dotfiles-backup-${BACKUP_STAMP}"
    [[ ! -e "$backup" && ! -L "$backup" ]] || {
        echo "Backup target already exists: $backup" >&2
        return 1
    }
}

link_config() {
    local src=$1
    local dest=$2

    if same_link "$src" "$dest"; then
        echo "Already linked: $dest -> $src"
        return
    fi

    run mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" || -L "$dest" ]]; then
        local backup="${dest}.dotfiles-backup-${BACKUP_STAMP}"
        run mv "$dest" "$backup"
        if $DRY_RUN; then
            echo "Would back up: $dest -> $backup"
        else
            echo "Backed up: $dest -> $backup"
        fi
    fi

    run ln -s "$src" "$dest"
    if $DRY_RUN; then
        echo "Would link: $dest -> $src"
    else
        echo "Linked: $dest -> $src"
    fi
}

for command in git nvim wezterm yazi tmux; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Warning: command not found: $command" >&2
    fi
done

sources=(
    "$DOTFILES/nvim"
    "$DOTFILES/tmux/.tmux/.tmux.conf"
    "$DOTFILES/tmux/.tmux/.tmux.conf.local"
    "$DOTFILES/wezterm"
    "$DOTFILES/yazi/config"
)
targets=(
    "$CONFIG_HOME/nvim"
    "$HOME/.tmux.conf"
    "$HOME/.tmux.conf.local"
    "$CONFIG_HOME/wezterm"
    "$CONFIG_HOME/yazi"
)
names=("Neovim" "tmux main config" "tmux local config" "WezTerm" "Yazi")

# Git is required for TPM; fail before changing any configuration.
tpm_dir="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$tpm_dir" ]] && ! $DRY_RUN && ! command -v git >/dev/null 2>&1; then
    echo "Cannot install TPM because git is not available." >&2
    exit 1
fi

# Preflight every target before changing anything.
for i in "${!sources[@]}"; do
    assert_linkable "${sources[$i]}" "${targets[$i]}"
done

for i in "${!sources[@]}"; do
    echo "==> Linking ${names[$i]}"
    link_config "${sources[$i]}" "${targets[$i]}"
done

echo "==> Installing TPM if missing"
if [[ ! -d "$tpm_dir" ]]; then
    run mkdir -p "$(dirname "$tpm_dir")"
    run git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
else
    echo "TPM already installed: $tpm_dir"
fi

echo "All done."
