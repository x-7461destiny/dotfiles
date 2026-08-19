#!/usr/bin/env bash
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
failures=0
warnings=0

ok() { printf '[OK]   %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; failures=$((failures + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

check_required_command() {
    if command -v "$1" >/dev/null 2>&1; then
        ok "$1: $(command -v "$1")"
    else
        fail "$1 is required but was not found"
    fi
}

check_optional_command() {
    if command -v "$1" >/dev/null 2>&1; then
        ok "$1: $(command -v "$1")"
    else
        warn "$1 is not installed; its configuration will remain unused"
    fi
}

check_link() {
    local name=$1
    local source=$2
    local target=$3

    if [[ -L "$target" ]]; then
        if [[ "$(readlink "$target")" == "$source" ]]; then
            ok "$name link: $target"
        else
            warn "$name points somewhere else: $target -> $(readlink "$target")"
        fi
    elif [[ -e "$target" ]]; then
        warn "$name target already exists and is not a symbolic link: $target"
    else
        info "$name is not deployed yet: $target"
    fi
}

printf 'Dotfiles doctor (Linux)\nRepository: %s\n\n' "$DOTFILES"

for path in nvim tmux wezterm yazi install; do
    [[ -e "$DOTFILES/$path" ]] && ok "repository path: $path" || fail "missing repository path: $path"
done

printf '\nInstaller requirements\n'
for command in bash git mkdir mv ln readlink date; do
    check_required_command "$command"
done

printf '\nConfigured applications\n'
for command in nvim tmux wezterm yazi; do
    check_optional_command "$command"
done
for command in rg fd fzf nc; do
    check_optional_command "$command"
done

printf '\nFonts\n'
if command -v fc-list >/dev/null 2>&1; then
    if fc-list : family 2>/dev/null | grep -Eiq 'JetBrains Mono|Nerd Font'; then
        ok 'JetBrains Mono or a Nerd Font was detected'
    else
        warn 'JetBrains Mono/Nerd Font was not detected; terminal icons may be missing'
    fi
else
    warn 'fc-list is unavailable; font presence could not be checked'
fi

printf '\nMachine-specific configuration\n'
if [[ -f "$DOTFILES/wezterm/config/machine_local.lua" ]]; then
    ok 'wezterm/config/machine_local.lua exists and is Git-ignored'
else
    info 'No machine_local.lua; portable defaults will be used'
    info 'Copy wezterm/config/machine.example.lua to machine_local.lua to customize this machine'
fi

printf '\nDeployment status\n'
check_link 'Neovim' "$DOTFILES/nvim" "$CONFIG_HOME/nvim"
check_link 'tmux main' "$DOTFILES/tmux/.tmux/.tmux.conf" "$HOME/.tmux.conf"
check_link 'tmux local' "$DOTFILES/tmux/.tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
check_link 'WezTerm' "$DOTFILES/wezterm" "$CONFIG_HOME/wezterm"
check_link 'Yazi' "$DOTFILES/yazi/config" "$CONFIG_HOME/yazi"

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
((failures == 0))
