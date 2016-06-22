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
  (not (null (member dict (nsspell-list-languages)))))

(defun nsspell-check-word (word &optional dict)
  "Check if WORD is spelled correctly (in optional DICT) using
the OS X spell checker.

DICT is an optional string specifying the language that should be
used by the spell checker. Call `nsspell-list-languages' to see
which languages are available.

When WORD is correct, return t. Otherwise, return a list of
suggestions for WORD."
  (if dict
      (progn
	(cl-assert (nsspell-dictionary-p dict))
	(nsspell--check-word word dict))
    (nsspell--check-word word)))

(defun nsspell-suggestions-for (word &optional dict)
  "List spelling suggestions for WORD (in optional DICT) using
the OS X spell checker.

DICT is an optional string specifying the language that should be
used by the spell checker. Call `nsspell-list-languages' to see
which languages are available.

Note that this function will be happy to return suggestions for
correctly-spelled words. And there may be no suggestions at all."
  (if dict
      (progn
	(cl-assert (nsspell-dictionary-p dict))
	(nsspell--suggestions-for word dict))
    (nsspell--suggestions-for word)))

(provide 'nsspell)
