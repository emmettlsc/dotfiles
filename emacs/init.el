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

;; Line numbers when editing code (off in shells, dired, etc.).
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

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

;; provide init
(provide 'init)
;;; init.el ends here
