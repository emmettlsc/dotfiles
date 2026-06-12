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
└── emacs/init.el
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

`init.el` only changes one thing: brightens the default dark-blue used for `dired-directory` and `font-lock-function-name-face` to a Nord cyan (`#88c0d0`) so folders are readable on a black terminal.

## tmux

- Prefix + `r` reloads the config (`bind r source-file ~/.tmux.conf`).
- Prefix + `|` splits horizontally, prefix + `-` splits vertically (each inherits the pane's current path).
- Emacs-style mode keys, Nord-ish status bar, windows numbered from 1.
