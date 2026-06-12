;;; init.el --- minimal personal config -*- lexical-binding: t -*-

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
