#!/usr/bin/env bash
set -e

DOTFILES=$HOME/dotfiles

link() {
    src=$1
    dest=$2

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "Removing existing: $dest"
        rm -rf "$dest"
    fi

    ln -s "$src" "$dest"
    echo "Linked $dest -> $src"
}

echo "==> Linking Neovim"
link "$DOTFILES/nvim" "$HOME/.config/nvim"

echo "==> Linking tmux"
link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "==> Installing TPM if missing"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "==> Linking WezTerm"
link "$DOTFILES/wezterm/wezterm.lua" "$HOME/.wezterm.lua"

echo "All done 🎉"

