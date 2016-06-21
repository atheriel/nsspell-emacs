(defvar nsspell--available nil)
(defun nsspell-available-p ()
  "Return t if `nsspell-native' is available on this platform."
  (interactive)
  nsspell--available)

;; We can only load this on Mac OS X systems for Emacs versions that
;; support dynamic modules.
(when (and (eq system-type 'darwin)
	   (not (null module-file-suffix))
	   (require 'nsspell-native nil 'noerror))
  (setq nsspell--available t))

(provide 'nsspell)
