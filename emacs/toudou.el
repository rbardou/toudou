(defvar toudou-mode-syntax-table
  (let ((st (make-syntax-table)))
    st)
  "Syntax table for `toudou-mode'.")

; see: https://www.emacswiki.org/emacs/RegularExpression
; and: https://www.gnu.org/software/emacs/manual/html_node/elisp/Faces-for-Font-Lock.html
(defconst toudou-font-lock-keywords
  (list
   '("\\(([^)]+)\\)"
     . font-lock-keyword-face)
   '("^\\([^-].+\\)"
     . font-lock-keyword-face)
   '("^\\(- \\[[xX]\\].+\\)"
     . font-lock-constant-face)
  )
  "Font lock for `toudou-mode'.")

(define-derived-mode toudou-mode fundamental-mode "Toudou"
  "A major mode for editing Toudou files"
  :syntax-table toudou-mode-syntax-table
  (set (make-local-variable 'font-lock-defaults) '(toudou-font-lock-keywords)))

(add-to-list 'auto-mode-alist '("\\.todo\\'" . toudou-mode))

(defun save-and-run-toudou ()
 "Save current buffer, run toudou, and revert buffer."
 (interactive)
 (progn
  (save-buffer)
  (shell-command (concat "toudou " (buffer-file-name)))
  (revert-buffer 1 1)))

(add-hook 'toudou-mode-hook
 (lambda () (local-set-key (kbd "C-x C-s") #'save-and-run-toudou)))

(provide 'toudou)
