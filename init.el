;; General Setup --------------------------------------------------------------

;; Added by Package.el.  This must come before configurations of
;; installed packages.
(package-initialize)

;; custom set variables, can only be one instance
(custom-set-variables
 '(custom-enabled-themes (quote (tango-dark)))
 '(elpy-modules
   (quote
    (elpy-module-company elpy-module-eldoc elpy-module-flymake elpy-module-pyvenv elpy-module-yasnippet elpy-module-sane-defaults)))
 '(package-selected-packages (quote (auctex ggtags elpy jedi marmalade-demo))))
(custom-set-faces)


(setq default-directory "~/MEGA/VM_VirtualBox" )
(setq bongo-default-directory "~/MEGA/Music/Bongo/")
(setq last-kbd-macro
   nil)

(let ((default-directory  "~/MEGA/VM_VirtualBox/emacs.d/lisp/"))
  (normal-top-level-add-subdirs-to-load-path))

;; additional elisp paths
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives
'("marmalade" . "http://marmalade-repo.org/packages/"))


;; load additional .el files
(load "~/MEGA/VM_VirtualBox/emacs.d/lisp/autopair.el")

;; make emacs open full screen 
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; set the opening screen to blank scratch page
(setq inhibit-splash-screen t)
(setq initial-scratch-message nil)

;;load packages
(require 'ssh)
(require 'tramp)
(require 'package)
(require 'ido)
(require 'ess-site)
(require 'textmate)
(require 'magit)
(require 'auto-complete)
(require 'elpy)
(require 'w3)
(require 'autopair)

;; file backup settings
;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))


;; prevent writing of tramp_hostory files
(setq tramp-histfile-override "/dev/null")


;; package specs
(ido-mode t)
(autopair-global-mode)
(elpy-enable)
(setenv "PYTHONPATH" "/usr/bin/python")
(setenv "SCALA_HOME" "/usr/local/bin/scala")



;;R auto-complete
(setq ess-use-auto-complete t)
(ess-toggle-underscore nil)
(global-auto-complete-mode)

;; C++ mode
(add-hook 'c-mode-common-hook
          (lambda ()
            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode 'asm-mode)
              (ggtags-mode 1))))





;; TEX mode
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq TeX-save-query nil)
(setq TeX-PDF-mode t)
(setq-default TeX-master nil)
(add-hook 'LaTeX-mode-hook 'visual-line-mode)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(setq reftex-plug-into-AUCTeX t)
;;(load "auctex.el" nil t t)

;; to load TeX packages, put .sty file at:
;; /usr/share/texlive/texmf-dist/text
;; use root (sudo -s)



;; Custom Functions -------------------------------------------------------------------

;; function to open a new blank buffer
(defun j-new-buffer ()
  "Open a new empty buffer."
  (interactive)
  (let ((-buf (generate-new-buffer "untitled")))
    (switch-to-buffer -buf)
    (funcall (and initial-major-mode))
    (setq buffer-offer-save t)))

;; functions for python mode
(defun forward-block (&optional Ï†n)
  (interactive "p")
  (let ((Ï†n (if (null Ï†n) 1 Ï†n)))
    (search-forward-regexp "\n[\t\n ]*\n+" nil "NOERROR" Ï†n)))

(defun elpy-shell-send-current-block ()
  "Send current block to Python shell."
  (interactive)
  (beginning-of-line)
  (push-mark)
  (forward-block)
  (elpy-shell-send-region-or-buffer)
  (display-buffer (process-buffer (elpy-shell-get-or-create-process))
                  nil
                  'visible))


;; function to evaluate lisp
(defun eval-region-or-buffer ()
  (interactive)
  (let ((debug-on-error t))
    (cond
     (mark-active
      (call-interactively 'eval-region)
      (message "Region evaluated")
      (setq deactivate-mark t))
     (t
      (eval-buffer)
      (message "Buffer evaluated")))))

(global-set-key (kbd "C-x C-k e") 'eval-region-or-buffer)


(defun sudo-edit (&optional arg)
  "Edit currently visited file as root.
With a prefix ARG prompt for a file to visit.
Will also prompt for a file to visit if current
buffer is not visiting a file."
  (interactive "P")
  (if (or arg (not buffer-file-name))
      (find-file (concat "/sudo:root@localhost:"
                         (ido-read-file-name "Find file(as root): ")))
    (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))


;; delete autosaves in current directory
(defun autosave-delete ()
  "Delete Emacs autosaved files in current directory"
  (interactive)
  (shell-command "rm $(find . -maxdepth 1 -type f -name \"*~\")"))



;; toggle images in eww browser
(defvar-local endless/display-images t)

(defun toggle-image-display ()
  "Toggle images display on current buffer."
  (interactive)
  (setq endless/display-images
        (null endless/display-images))
  (endless/backup-display-property endless/display-images))


(defun endless/backup-display-property (invert &optional object)
  "Move the 'display property at POS to 'display-backup.
Only applies if display property is an image.
If INVERT is non-nil, move from 'display-backup to 'display
instead.
Optional OBJECT specifies the string or buffer. Nil means current
buffer."
  (let* ((inhibit-read-only t)
         (from (if invert 'display-backup 'display))
         (to (if invert 'display 'display-backup))
         (pos (point-min))
         left prop)
    (while (and pos (/= pos (point-max)))
      (if (get-text-property pos from object)
          (setq left pos)
        (setq left (next-single-property-change pos from object)))
      (if (or (null left) (= left (point-max)))
          (setq pos nil)
        (setq prop (get-text-property left from object))
        (setq pos (or (next-single-property-change left from object)
                      (point-max)))
        (when (eq (car prop) 'image)
          (add-text-properties left pos (list from nil to prop) object))))))



;; Custom Macros --------------------------------------------------------

;; open new empty buffer
(global-set-key (kbd "C-x C-k n") 'j-new-buffer) 

;; macro to login to app15
(fset 'login-15
   [?\M-x ?e ?s ?h ?e ?l ?l return ?c ?d ?  ?/ ?j ?m ?c ?m ?i ?l ?l ?a ?n ?@ ?1 ?0 ?. ?9 ?6 ?. ?2 ?6 ?. ?6 ?3 ?:])
(global-set-key (kbd "C-x C-k 1") 'login-15)

;; IP for app01 is 10.96.26.57
;; IP for app02 is 10.96.26.47
;; IP for app21 is 10.96.26.70
;; IP for app22 is 10.96.26.71


;; macro to login to app16
(fset 'login-16
   [?\M-x ?e ?s ?h ?e ?l ?l return ?c ?d ?  ?/ ?j ?m ?c ?m ?i ?l ?l ?a ?n ?@ ?1 ?0 ?. ?9 ?6 ?. ?2 ?6 ?. ?6 ?4 ?:])
(global-set-key (kbd "C-x C-k 2") 'login-16)

;; login to devapp04

(fset 'login-devapp1
   [?\M-x ?e ?s ?h ?e ?l ?l return ?c ?d ?  ?/ ?j ?m ?c ?m ?i ?l ?l ?a ?n ?@ ?1 ?0 ?. ?9 ?6 ?. ?2 ?6 ?. ?5 ?0 ?:])
(global-set-key (kbd "C-x C-k d") 'login-devapp1)

(setq last-kbd-macro
   nil)


;; macro to open the configuration file
(fset 'open-config
   [?\C-x ?\C-f ?~ ?/ ?M ?E ?G ?A ?/ ?V ?M ?_ ?V tab ?e ?m ?a ?c ?s ?. ?d ?/ ?i ?n ?i ?t ?. ?e ?l return])


;; macro to go to timesheet directory
(fset 'timesheet-dir
   [?\M-x ?e ?s ?h tab return ?c ?d ?  ?~ ?/ ?D ?o ?c ?u tab ?O ?r ?g tab ?T ?i ?m ?e tab return])


;; macros to navigate windows
(global-set-key (kbd "C-x <up>") 'windmove-up)
(global-set-key (kbd "C-x <down>") 'windmove-down)
(global-set-key (kbd "C-x <right>") 'windmove-right)
(global-set-key (kbd "C-x <left>") 'windmove-left) 
(global-set-key (kbd "C-S-x <left>") 'previous-buffer)
(global-set-key (kbd "C-S-x <right>") 'next-buffer)

;; set alt [ and ] be arrow keys
(global-set-key (kbd "M-[") [left])
(global-set-key (kbd "M-]") [right])
(global-set-key (kbd "M-p") [up])
(global-set-key (kbd "M-;") [down])
(global-set-key (kbd "M-'") [down])


;;macros to edit pane size
(global-set-key (kbd "M-<left>") 'shrink-window-horizontally)
(global-set-key (kbd "M-<right>") 'enlarge-window-horizontally)
(global-set-key (kbd "M-<down>") 'shrink-window)
(global-set-key (kbd "M-<up>") 'enlarge-window)



;; make C-return send line to python shell
(eval-after-load "elpy"
  '(define-key elpy-mode-map (kbd " <C-return>") 'elpy-shell-send-current-statement))

;; shift C-return sends block to python shell
(eval-after-load "elpy"
  '(define-key elpy-mode-map (kbd " <C-S-return>") 'elpy-shell-send-region-or-buffer))

(setq last-kbd-macro
   [?\M-x ?e ?s ?h ?e ?l ?l return ?c ?d ?  ?~ ?/ ?D ?o ?c ?u backspace backspace backspace ?r ?o ?p ?b ?o ?x ?/ ?V ?M ?_ ?V ?i ?r tab ?D ?o ?c ?u ?m ?e ?n ?t ?s ?/ ?O ?r ?g tab ?T ?i ?m ?e ?s ?h tab return])
;; macro for git-status
(global-set-key (kbd "C-x g") 'magit-status)


;;emmms player
(global-set-key (kbd "C-c e <up>") 'emms-start)
(global-set-key (kbd "C-c e <down>") 'emms-stop)
(global-set-key (kbd "C-c e <left>") 'emms-previous)
(global-set-key (kbd "C-c e <right>") 'emms-next)
