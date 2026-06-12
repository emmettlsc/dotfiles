#!/bin/sh
# Symlink dotfiles into $HOME. Backs up any existing non-symlink files to *.bak.
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
    src="$1"
    dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "backing up $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sfn "$src" "$dst"
    echo "linked $dst -> $src"
}

# shared
link "$DOTFILES/shared/aliases.sh"   "$HOME/.aliases"

# tmux
link "$DOTFILES/tmux/tmux.conf"      "$HOME/.tmux.conf"

# zsh
link "$DOTFILES/zsh/zshrc"           "$HOME/.zshrc"
link "$DOTFILES/zsh/zprofile"        "$HOME/.zprofile"

# bash
link "$DOTFILES/bash/bashrc"         "$HOME/.bashrc"
link "$DOTFILES/bash/bash_profile"   "$HOME/.bash_profile"

# csh/tcsh
link "$DOTFILES/csh/cshrc"           "$HOME/.cshrc"

# emacs
mkdir -p "$HOME/.emacs.d"
link "$DOTFILES/emacs/init.el"       "$HOME/.emacs.d/init.el"

echo
echo "done. open a new shell or 'source ~/.zshrc' to apply."
