(defvar nsspell--available nil)
(defun nsspell-available-p ()
  "Return t if `nsspell-native' is available on this platform."
  (interactive)
  nsspell--available)

;; These symbols are used by the native module to signal errors.
(define-error 'no-words-in-string "No words in string")
(define-error 'wrong-number-of-words "Wrong number of words")

;; We can only load this on Mac OS X systems for Emacs versions that
;; support dynamic modules.
(when (and (eq system-type 'darwin)
	   (not (null module-file-suffix))
	   (require 'nsspell-native nil 'noerror))
  (setq nsspell--available t))

(defun nsspell-dictionary-p (dict)
  "Return t if DICT is an available language from the OS X spell
checker."
  (not (null (member dict (nsspell--list-languages)))))

(provide 'nsspell)
