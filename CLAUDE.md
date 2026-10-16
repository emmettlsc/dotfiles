# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal dotfiles repo: shell (zsh/bash/csh), tmux, emacs, and git config, deployed into `$HOME` by symlink. There is no build, test, or lint step — the only "run" is `./install.sh`, and verification is opening a new shell.

## Commands

```sh
./install.sh                 # symlink everything into $HOME (idempotent, safe to re-run)
zsh -ic 'exit'               # smoke-test the interactive zsh path for errors
bash -ic 'exit'              # same for bash
tmux source-file ~/.tmux.conf
emacs --batch -l emacs/init.el   # check init.el loads clean
```

`install.sh` uses `ln -sfn`, so re-running is harmless. It backs up an existing target to `*.bak` **only if it is a real file, not a symlink** — so the first run preserves pre-existing configs and later runs never clobber the backup.

## Architecture

**Symlink, not copy.** Every deployed file is a symlink back into this repo, so editing `~/.zshrc` *is* editing `zsh/zshrc`. Never write a "fix" into `$HOME` and expect it to persist separately — it's the same file.

**`install.sh` is the deployment manifest.** The repo-path → `$HOME`-target mapping exists nowhere else. Adding a new dotfile means adding a `link` line there; without it the file is inert.

**Login vs. interactive split** is the organizing principle of the shell configs:

| | zsh | bash |
|---|---|---|
| env, PATH, `brew shellenv`, nvm, `LSCOLORS` | `zsh/zprofile` | `bash/bash_profile` |
| aliases, history, fzf, rbenv, conda | `zsh/zshrc` | `bash/bashrc` |

The two columns are deliberate mirrors — a change to one side usually needs the same change on the other. `bash_profile` ends by sourcing `.bashrc` (bash does not do this itself); zsh needs no equivalent.

**Aliases live in two places by necessity.** `shared/aliases.sh` is POSIX sh, symlinked to `~/.aliases` and sourced by both `zshrc` and `bashrc`. csh cannot parse it (`alias name 'cmd'`, no `=`), so `csh/cshrc` carries its own copy. **Adding an alias means editing both files.** csh also duplicates the PATH/LSCOLORS setup because it has no profile/rc split at all.

**Everything optional is guarded.** Sourcing follows `[ -f ... ] && source`, and tools are probed with `command -v`. The configs must stay no-op-safe on a machine without oh-my-zsh, fzf, zsh-autosuggestions, rbenv, conda, or nvm — preserve this pattern when adding anything.

**Git identity is out-of-repo.** `git/gitconfig` `[include]`s `~/.gitconfig.local`, which `install.sh` stubs out on first run. Never put a name or email in the committed `gitconfig`.

**Nord palette, shared by eye not by code.** `#88c0d0` (cyan accent), `#2e3440`, `#3b4252`, `#d8dee9`, `#81a1c1`, `#a3be8c` appear in both `tmux/tmux.conf` and `emacs/init.el`. There is no shared color file; keep new colors consistent with these.

## Conventions

- Comments explain *why*, especially where a setting compensates for something (e.g. `init.el` overriding `font-lock-function-name-face` because the default blue is unreadable on black).
- Section headers in the shell rc files use `# ----- name -----`.
- Keep `README.md` in sync: it documents the layout, the aliases rationale, and the optional-tools install lines.
