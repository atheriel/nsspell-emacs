(require 'nsspell)

(ert-deftest test-nsspell-check-word ()
  "Tests word checking in `nsspell' and `nsspell-native'."
  ;; Basic functionality.
  (should (equal t (nsspell-check-word "cello")))
  (should (equal t (nsspell-check-word "cello" "en_GB")))
  ;; Low-level interface.
  (should (equal t (nsspell--check-word "cello")))
  (should (equal t (nsspell--check-word "cello" "en_GB"))))

(ert-deftest test-nsspell-check-word-argument-errors ()
  "Tests word checking in `nsspell-native' for erroneous input."
  ;; Too many/few arguments.
  (should-error (nsspell--check-word))
  (should-error (nsspell--check-word "cello" "en_BG" "error?"))
  ;; Erroneous argument types.
  (should-error (nsspell--check-word 1))
  (should-error (nsspell--check-word "cello" 1))
  ;; No words.
  (should-error (nsspell--check-word ""))
  ;; Too many words.
  (should-error (nsspell--check-word "hells bells")))

(ert-deftest test-nsspell-suggestions-for ()
  "Test word suggestions in `nsspell' and `nsspell-native'."
  (should (< 0 (length (nsspell-suggestions-for "cello"))))
  ;; Low-level interface.
  (should (< 0 (length (nsspell--suggestions-for "cello")))))

(ert-deftest test-nsspell-dictionary-p ()
  "Tests the language listing capacity of `nsspell' and
`nsspell-native'."
  ;; Too many arguments.
  (should-error (nsspell-list-languages "error?"))
  ;; Low-level interface.
  (should (< 0 (length (nsspell-list-languages))))
  ;; It seems safe enough to assume that English is available.
  (should (equal t (nsspell-dictionary-p "en")))
  ;; But this one is unlikely.
  (should (equal nil (nsspell-dictionary-p "saskquatch"))))
