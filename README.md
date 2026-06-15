# dotfiles

Minimal, portable shell + tmux config.

## Install

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` symlinks files into `$HOME` and backs up anything it would overwrite to `*.bak`.

## Layout

```
.
├── tmux/tmux.conf
├── shared/aliases.sh     # POSIX aliases sourced by zsh and bash
├── zsh/{zshrc,zprofile}
├── bash/{bashrc,bash_profile}
├── csh/cshrc
├── emacs/init.el
└── git/gitconfig
```

## Where do aliases go?

There is no standard `.aliases` file — putting one in `$HOME` and sourcing it from each shell's rc is a convention, not a rule. Per shell, the canonical place is:

| Shell      | Aliases live in | Login-only env in     | Notes |
|------------|-----------------|-----------------------|-------|
| **zsh**    | `~/.zshrc`      | `~/.zprofile`         | `~/.zshenv` runs for *every* invocation incl. scripts — keep it tiny |
| **bash**   | `~/.bashrc`     | `~/.bash_profile`     | `.bash_profile` should source `.bashrc` so aliases work in login shells too |
| **csh/tcsh** | `~/.cshrc`    | `~/.login` (optional) | `.cshrc` runs for every invocation; there's no `.cprofile` |

This repo factors `ll` and `c` into `shared/aliases.sh` (POSIX sh syntax) and sources it from `.zshrc` and `.bashrc`. csh needs its own copy in `csh/cshrc` because its alias syntax differs (`alias name 'cmd'` — no `=`).

## emacs

- Brightens default dark-blue `dired-directory` / `font-lock-function-name-face` → Nord cyan `#88c0d0` (readable on a black terminal).
- `inhibit-startup-message`, silent bell.
- Backup (`~`) and auto-save (`#`) files redirected to `~/.emacs.d/backups/`.
- Line numbers on in `prog-mode` (code buffers only).

## git

`~/.gitconfig` includes `~/.gitconfig.local` for identity — `install.sh` writes a stub if it doesn't exist; edit it with your name/email. Key settings: `pull.rebase`, `push.autoSetupRemote`, `fetch.prune`, `rerere.enabled`, `merge.conflictstyle=zdiff3`. Aliases: `co sw br st cm ca lg last unstage`.

## optional tools

The shell config is no-op-safe if these aren't installed:

```
brew install fzf zsh-autosuggestions
$(brew --prefix)/opt/fzf/install   # writes ~/.fzf.zsh and ~/.fzf.bash
```

## tmux

- Prefix + `r` reloads the config.
- Prefix + `|` / `-` split panes, inheriting the current path.
- Mouse on, 50k-line scrollback, emacs-style mode keys, Nord-ish status bar, windows numbered from 1.
