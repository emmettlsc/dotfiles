;;; init.el --- minimal personal config -*- lexical-binding: t -*-

;; ---- behavior ----
(setq inhibit-startup-message t)
(setq ring-bell-function 'ignore)

;; Redirect backup (~) and auto-save (#) files into ~/.emacs.d/backups
;; instead of scattering them next to source files.
(let ((backup-dir (expand-file-name "backups" user-emacs-directory)))
  (unless (file-directory-p backup-dir)
    (make-directory backup-dir t))
  (setq backup-directory-alist `(("." . ,backup-dir)))
  (setq auto-save-file-name-transforms `((".*" ,backup-dir t))))

;; Line numbers in every buffer, not just code. To claw back the ones that
;; are noise (shells, dired, help), add a hook setting
;; `display-line-numbers-mode' to -1 rather than narrowing this back to
;; `prog-mode-hook'.
(global-display-line-numbers-mode 1)

;; ---- indentation: real tabs, displayed 4 columns wide ----
;; Indent with actual TAB characters and render them 4 columns. `tab-width'
;; and each mode's indent offset must stay equal, or one level of indent stops
;; being exactly one tab.
(setq-default indent-tabs-mode t)
(setq-default tab-width 4)
(setq c-ts-mode-indent-offset 4
      sh-basic-offset 4
      ;; Python indents with spaces (see below), but 4 of them.
      python-indent-offset 4
      cmake-ts-mode-indent-offset 4
      json-ts-mode-indent-offset 4)

;; Two languages opt out, and not as a matter of taste:
;; YAML forbids tab characters for indentation outright -- a tab there is a
;; parse error, not a style difference. Python 3 raises TabError on mixed
;; indentation and its entire toolchain assumes 4 spaces, so hard tabs would
;; fight every formatter and diff. Both stay on spaces.
(dolist (hook '(yaml-ts-mode-hook python-ts-mode-hook))
  (add-hook hook (lambda () (setq indent-tabs-mode nil))))

;; ---- readable colors on a black terminal ----
;; The default emacs blue used for directory names (dired) and function
;; names (font-lock) is too dark to read on a black background. Override
;; with a brighter cyan from the Nord palette.

(defconst my/dir-color "#88c0d0")

;; dired folder names
(with-eval-after-load 'dired
  (set-face-attribute 'dired-directory nil
                      :foreground my/dir-color
                      :weight 'bold))

;; dired-directory inherits from this in some emacs versions, and it's the
;; same dim blue used for function names in code — brighten both at once.
(set-face-attribute 'font-lock-function-name-face nil
                    :foreground my/dir-color)

;; ---- Go ----
;; Every Emacs-side piece here is built in to Emacs 30 — tree-sitter
;; (`treesit'), `go-ts-mode', and the `eglot' LSP client. No package manager.
;;
;; The external dependency is the language server, installed into
;; $(go env GOPATH)/bin:
;;   go install golang.org/x/tools/gopls@latest
;;   go install github.com/go-delve/delve/cmd/dlv@latest   # debugger, optional
;;
;; Tree-sitter grammars are compiled shared libraries under
;; ~/.emacs.d/tree-sitter/ — machine-local, so they are not in this repo. On a
;; new machine (needs a C compiler):
;;   M-x treesit-install-language-grammar RET go    RET
;;   M-x treesit-install-language-grammar RET gomod RET
(setq treesit-language-source-alist
      '((go    . ("https://github.com/tree-sitter/tree-sitter-go"))
        (gomod . ("https://github.com/camdencheek/tree-sitter-go-mod"))))

;; `go-ts-mode' adds these itself, but only as a side effect of being loaded —
;; and it is merely autoloaded, so nothing loads it until a .go buffer already
;; picked a major mode. Chicken and egg; map the extensions here instead.
(add-to-list 'auto-mode-alist '("\\.go\\'"     . go-ts-mode))
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))

;; `go install' writes to $GOPATH/bin, which is on no PATH here — and a GUI
;; Emacs on macOS inherits no shell PATH at all. Tell Emacs directly, so eglot
;; finds gopls however Emacs was started.
(let ((gobin (expand-file-name "bin" (or (getenv "GOPATH") "~/go"))))
  (when (file-directory-p gobin)
    (add-to-list 'exec-path gobin)
    (setenv "PATH" (concat gobin path-separator (getenv "PATH")))))

;; gofmt indents with tabs, so only the *display* width is a preference; the
;; default 8 wastes a lot of screen on nested code. Keep the two in step —
;; `go-ts-mode-indent-offset' is columns per level, so offset = tab-width
;; means exactly one tab per level.
(setq go-ts-mode-indent-offset 4)

(with-eval-after-load 'eglot
  ;; The event log is a memory hog on a big workspace and is only useful when
  ;; debugging the server itself (set :size to nil to turn it back on).
  (setq eglot-events-buffer-config '(:size 0 :format full))
  ;; Shut gopls down with the last Go buffer instead of leaving it resident.
  (setq eglot-autoshutdown t)
  ;; Keep M-. working *inside* jumped-to files in the module cache, which are
  ;; outside the project and would otherwise lose LSP support.
  (setq eglot-extend-to-xref t)
  ;; gopls is conservative by default; turn on the analyses worth having.
  (setq-default eglot-workspace-configuration
                '(:gopls
                  (:staticcheck t
                   :usePlaceholders t
                   :analyses (:unusedparams t
                              :unusedwrite t
                              :nilness t
                              :shadow t)
                   ;; Inlay hints stay off until gopls is asked for them, so
                   ;; `eglot-inlay-hints-mode' shows nothing by default.
                   ;; Uncomment for parameter names etc. inline:
                   ;; :hints (:parameterNames t :assignVariableTypes t
                   ;;         :compositeLiteralFields t :rangeVariableTypes t)
                   ))))

;; Diagnostics reach the buffer through flymake (eglot feeds it), but flymake
;; ships *no* default keybindings — its commands are M-x-only out of the box.
;; Error-to-error is a high-frequency motion, so bind it; the rest of eglot's
;; commands stay on M-x, where they are discoverable by name.
(with-eval-after-load 'flymake
  (keymap-set flymake-mode-map "C-c ! n" #'flymake-goto-next-error)
  (keymap-set flymake-mode-map "C-c ! p" #'flymake-goto-prev-error)
  (keymap-set flymake-mode-map "C-c ! l" #'flymake-show-buffer-diagnostics)
  (keymap-set flymake-mode-map "C-c ! P" #'flymake-show-project-diagnostics))

(defun my/go-organize-imports ()
  "Apply gopls' `source.organizeImports' code action to the whole buffer.
Deliberately bypasses `eglot-code-actions'' interactive path, which
prompts when a server offers more than one action and signals an error
when it offers none — neither is acceptable on `before-save-hook'."
  (when-let* ((server (eglot-current-server))
              (actions (eglot-code-actions (point-min) (point-max)
                                           "source.organizeImports")))
    (dolist (action actions)
      (eglot-execute server action))))

(defun my/go-before-save ()
  "gofmt the buffer and fix up its import block, i.e. what goimports does.
Both halves come from gopls, so this is a no-op until it has connected."
  (when (eglot-managed-p)
    ;; Imports first: formatting the result is cheap, re-sorting a formatted
    ;; buffer is not necessarily idempotent.
    (ignore-errors (my/go-organize-imports))
    (ignore-errors (eglot-format-buffer))))

(defun my/go-test (&optional whole-module)
  "Run `go test' on the package of the current buffer.
With prefix arg WHOLE-MODULE, run it over ./... from the project root.
-count=1 defeats Go's test result cache, which otherwise makes a re-run
after an unrelated edit look like it passed without running."
  (interactive "P")
  (let ((default-directory
         (if whole-module (project-root (project-current t))
           (file-name-directory (buffer-file-name)))))
    (compile (if whole-module "go test ./..." "go test -v -count=1 ."))))

(defun my/go-setup ()
  "Buffer-local Go setup: start gopls, format on save, 4-column tabs."
  (setq tab-width 4)                    ; must match go-ts-mode-indent-offset
  (eglot-ensure)
  ;; Inline completion suggestions as you type (built in to Emacs 30);
  ;; candidates themselves still come from eglot via `completion-at-point'.
  (completion-preview-mode 1)
  (add-hook 'before-save-hook #'my/go-before-save nil t))

(add-hook 'go-ts-mode-hook #'my/go-setup)

;; C-c C-d is already `go-ts-mode-docstring'; C-c C-t is free.
(with-eval-after-load 'go-ts-mode
  (keymap-set go-ts-mode-map "C-c C-t" #'my/go-test))

;; ---- C/C++ (.H/.C), CUDA, Python, bash, YAML, Containerfiles, CMake ----
;; Same philosophy as the Go block above: every mode here is an Emacs 30
;; built-in `*-ts-mode' driven by `eglot', so there is still no package
;; manager. What has to exist per machine is the compiled grammar in
;; ~/.emacs.d/tree-sitter/ plus the server on PATH:
;;
;;   clangd   C, C++, CUDA  -- prebuilt LLVM release binary
;;   pylsp    Python        -- pip install python-lsp-server
;;   (bash)   shellcheck    -- not an LSP; flymake shells out to it directly
;;
;; YAML and Containerfiles intentionally get no language server: the whole
;; value of yaml-language-server is SchemaStore lookups over HTTPS, which is
;; dead weight on an air-gapped box.

(dolist (src '((c          . ("https://github.com/tree-sitter/tree-sitter-c"))
               (cpp        . ("https://github.com/tree-sitter/tree-sitter-cpp"))
               (python     . ("https://github.com/tree-sitter/tree-sitter-python"))
               (bash       . ("https://github.com/tree-sitter/tree-sitter-bash"))
               (yaml       . ("https://github.com/ikatyang/tree-sitter-yaml"))
               (dockerfile . ("https://github.com/camdencheek/tree-sitter-dockerfile"))
               (cmake      . ("https://github.com/uyha/tree-sitter-cmake"))
               (json       . ("https://github.com/tree-sitter/tree-sitter-json"))))
  (add-to-list 'treesit-language-source-alist src))

(defun my/ts-route (lang mode &rest patterns)
  "Send files matching PATTERNS to MODE, but only if LANG's grammar loaded.
A `*-ts-mode' whose grammar is missing fails on buffer entry, so where the
grammar was never compiled it is better to leave the old mode in place.
`treesit-language-available-p' is the quiet test for that -- `treesit-ready-p'
spews a multi-line dlopen warning per miss at startup."
  (when (treesit-language-available-p lang)
    (dolist (p patterns)
      (add-to-list 'auto-mode-alist (cons p mode)))))

;; .H and .C are C++ in the work tree -- not C, not Objective-C. Emacs maps
;; .C to c++-mode only on a case-sensitive filesystem and sends .H to c-mode,
;; so both need saying out loud; otherwise a case-insensitive Mac silently
;; opens them in the wrong mode.
(my/ts-route 'cpp 'c++-ts-mode
             "\\.H\\'" "\\.C\\'" "\\.cc\\'" "\\.cpp\\'" "\\.cxx\\'"
             "\\.hpp\\'" "\\.hh\\'" "\\.hxx\\'"
             ;; CUDA: the cpp grammar handles device code except the <<<...>>>
             ;; launch syntax, which parses as an ERROR node and costs a little
             ;; font-locking. clangd itself treats .cu as CUDA properly.
             "\\.cu\\'" "\\.cuh\\'")
(defun my/c-dialect-by-case ()
  "Pick the C or C++ mode for a .c/.C/.h/.H file, honoring the name's case.
`set-auto-mode' matches `auto-mode-alist' with `case-fold-search' forced on
whenever the filesystem is case-insensitive -- which macOS is -- making
`\\.C\\'' and `\\.c\\'' the same pattern and sending widget.C to `c-ts-mode'.
Reading the extension off the name directly is the only way to tell them
apart on both platforms."
  (pcase (file-name-extension (or buffer-file-name ""))
    ((or "C" "H") (c++-ts-mode))
    ("c" (c-ts-mode))
    ;; A lowercase .h could be either dialect; this one sniffs the contents.
    (_ (c-or-c++-ts-mode))))

(my/ts-route 'cpp 'my/c-dialect-by-case "\\.[cChH]\\'")
(my/ts-route 'python 'python-ts-mode "\\.py[iw]?\\'")
(my/ts-route 'bash 'bash-ts-mode "\\.sh\\'" "\\.bash\\(rc\\|_profile\\)?\\'")
(my/ts-route 'yaml 'yaml-ts-mode "\\.ya?ml\\'")
;; Podman's Containerfile is the same grammar as Dockerfile. Match a bare name
;; or a suffixed variant (Containerfile.gpu, Dockerfile.ci).
(my/ts-route 'dockerfile 'dockerfile-ts-mode
             "/\\(Containerfile\\|Dockerfile\\)\\(\\.[^/]*\\)?\\'"
             "\\.\\(containerfile\\|dockerfile\\)\\'")
(my/ts-route 'cmake 'cmake-ts-mode "/CMakeLists\\.txt\\'" "\\.cmake\\'")
(my/ts-route 'json 'json-ts-mode "\\.json\\'")

;; Files that reach a major mode some other way -- a #! line, `normal-mode',
;; a directory-local setting -- never consult `auto-mode-alist', so point the
;; classic modes at their tree-sitter equivalents as well.
(dolist (r '((c-mode      c-ts-mode      c)
             (c++-mode    c++-ts-mode    cpp)
             (python-mode python-ts-mode python)
             (sh-mode     bash-ts-mode   bash)))
  (when (treesit-language-available-p (nth 2 r))
    (add-to-list 'major-mode-remap-alist (cons (nth 0 r) (nth 1 r)))))

(with-eval-after-load 'eglot
  ;; eglot ships a clangd entry, but it covers c/c++/objc-mode only -- not
  ;; `c-or-c++-ts-mode' -- and passes no arguments. add-to-list prepends, so
  ;; this one is consulted first.
  ;;   --background-index        what makes M-. usable across a large tree
  ;;   --header-insertion=never  auto-inserted #includes guess wrong in a tree
  ;;                             that has its own include conventions
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c++-ts-mode c-or-c++-ts-mode)
                 . ("clangd" "--background-index" "--clang-tidy"
                    "--header-insertion=never" "--completion-style=detailed"))))

;; clangd learns the compile flags from compile_commands.json. Build systems
;; that do not emit one (anything older than cmake/bear) leave clangd guessing,
;; so for those trees drop a compile_flags.txt at the source root instead --
;; one flag per line:
;;   -xc++
;;   -std=c++17
;;   -I<include root>

(defconst my/lsp-executable
  '((c-ts-mode      . "clangd")
    (c++-ts-mode    . "clangd")
    (python-ts-mode . "pylsp"))
  "Server binary per major mode.
`eglot-ensure' defers its connect to `post-command-hook', so a missing
binary surfaces as an error *after* the buffer is already open rather than
as a no-op. Checking first keeps a machine that has only some of these
toolchains quiet.")

(defun my/eglot-light ()
  "Start the language server, if present, and inline completion.
No format-on-save, deliberately unlike `my/go-setup': gofmt is canonical for
Go so reformatting costs nothing, but running clang-format or ruff across a
file in a tree that was never formatted that way turns one edit into a
whole-file diff."
  (when-let* ((exe (alist-get major-mode my/lsp-executable))
              ((executable-find exe)))
    (eglot-ensure))
  (completion-preview-mode 1))

(dolist (h '(c-ts-mode-hook c++-ts-mode-hook python-ts-mode-hook))
  (add-hook h #'my/eglot-light))

;; bash gets no language server: `bash-ts-mode' already registers
;; `sh-shellcheck-flymake' as a flymake backend, so shellcheck on PATH is the
;; entire setup -- and the C-c ! bindings above work there unchanged.
(add-hook 'bash-ts-mode-hook
          (lambda ()
            (when (executable-find "shellcheck")
              (flymake-mode 1))))

;; provide init
(provide 'init)
;;; init.el ends here
