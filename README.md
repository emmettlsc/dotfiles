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

### Go

Built entirely on Emacs 30 built-ins — `treesit`, `go-ts-mode`, `eglot`. **No packages, no package manager.** Requires Emacs 30+ (`go-ts-mode` and tree-sitter are not in 28).

Per-machine setup, neither of which lives in this repo:

```sh
go install golang.org/x/tools/gopls@latest           # language server (required)
go install github.com/go-delve/delve/cmd/dlv@latest  # debugger (optional)
```

```
M-x treesit-install-language-grammar RET go    RET   # needs a C compiler
M-x treesit-install-language-grammar RET gomod RET
```

Grammars compile to `~/.emacs.d/tree-sitter/libtree-sitter-*.dylib`; the URLs come from `treesit-language-source-alist` in `init.el`.

| | |
|---|---|
| `M-.` / `M-,` | jump to definition / back (xref via gopls) |
| `M-?` | find references |
| `C-c C-t` | `go test -v -count=1 .` on this package; `C-u C-c C-t` → `go test ./...` from the project root |
| `C-c C-d` | `go-ts-mode-docstring` (built in to `go-ts-mode`) |
| `C-x p c` | `project-compile` — arbitrary build/test command at the project root |
| `C-M-i` | completion at point; inline suggestions come from `completion-preview-mode` |
| save | gopls organizes imports then gofmts — equivalent to `goimports` |

Diagnostics arrive through flymake. It ships no default bindings, so `init.el` adds `C-c ! n` / `C-c ! p` (next/prev error), `C-c ! l` (list for this buffer) and `C-c ! P` (whole project). Enabled are gopls' `staticcheck` plus the `unusedparams`/`unusedwrite`/`nilness`/`shadow` analyses enabled. Inlay hints are configured but commented out in `init.el`.

Tabs display at width 4 rather than Go's default 8 (`tab-width` and `go-ts-mode-indent-offset` must stay equal — one tab per level). gofmt still writes real tabs, so this is a display choice only and changes nothing on disk.

### other languages

C/C++ (`.H`/`.C`), CUDA, Python, bash, YAML, Containerfiles, CMake and JSON use
the same approach as Go: built-in `*-ts-mode` + `eglot`, **no packages**. Per
machine you need the grammar compiled into `~/.emacs.d/tree-sitter/` and the
server on `PATH`:

| language | mode | server | install |
|---|---|---|---|
| C++ (`.H .C .cc .cpp .hpp .cu .cuh`) | `c++-ts-mode` | `clangd` | prebuilt LLVM release binary |
| C (`.c`, `.h` by content) | `c-ts-mode` | `clangd` | same |
| Python | `python-ts-mode` | `pylsp` | `pip install python-lsp-server` |
| bash | `bash-ts-mode` | none | `shellcheck` on `PATH` (flymake calls it) |
| YAML / Containerfile / CMake / JSON | `*-ts-mode` | none | grammar only |

`.H` and `.C` are treated as **C++**, not C and not Objective-C. This needs a
dispatcher rather than an `auto-mode-alist` regexp: `set-auto-mode` matches the
alist with `case-fold-search` forced on whenever the filesystem is
case-insensitive, so on macOS `\.C\'` and `\.c\'` are the same pattern and
`widget.C` would open in `c-ts-mode`. `my/c-dialect-by-case` reads the
extension off the name instead, which behaves the same on APFS and on ext4.

No format-on-save outside Go: `gofmt` is canonical so reformatting is free,
but clang-format or ruff over a file in a tree that was never formatted that
way turns one edit into a whole-file diff.

clangd needs the compile flags. With no `compile_commands.json` (older build
systems emit none), drop a `compile_flags.txt` at the source root, one flag per
line (`-xc++`, `-std=c++17`, `-I...`).

Grammars are compiled, machine-local artifacts, so they are not in this repo.
With network: `M-x treesit-install-language-grammar`. Air-gapped: compile from
source tarballs — `gcc -fPIC -c src/parser.c` plus `src/scanner.c`/`.cc` if
present, linked to `libtree-sitter-<lang>.so`. Note a `.cc` scanner (yaml) must
link through `g++`.

## git

`~/.gitconfig` includes `~/.gitconfig.local` for identity — `install.sh` writes a stub if it doesn't exist; edit it with your name/email. Key settings: `pull.rebase`, `push.autoSetupRemote`, `fetch.prune`, `rerere.enabled`, `merge.conflictstyle=zdiff3`. Aliases: `co sw br st cm ca lg last unstage`.

## optional tools

The shell config is no-op-safe if these aren't installed:

```
brew install fzf zsh-autosuggestions
$(brew --prefix)/opt/fzf/install   # writes ~/.fzf.zsh and ~/.fzf.bash
```

`$HOME/go/bin` is prepended to `PATH` in `zprofile` / `bash_profile` / `cshrc` when it exists — `go install` writes there and nothing else puts it on `PATH`, so `gopls`, `dlv` and `staticcheck` are otherwise invisible to both the shell and Emacs.

## tmux

- Prefix + `r` reloads the config.
- Prefix + `|` / `-` split panes, inheriting the current path.
- Mouse on, 50k-line scrollback, emacs-style mode keys, Nord-ish status bar, windows numbered from 1.
