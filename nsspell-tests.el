(require 'nsspell)

(ert-deftest test-nsspell--check-word ()
  "Tests word checking in `nsspell-native'."
  ;; Basic functionality.
  (should (equal t (nsspell--check-word "cello")))
  (should (equal t (nsspell--check-word "cello" "en_GB"))))

(ert-deftest test-nsspell--check-word-argument-errors ()
  "Tests word checking in `nsspell-native' for erroneous input."
  ;; Erroneous argument types.
  (should-error (nsspell--check-word 1))
  (should-error (nsspell--check-word "cello" 1))
  ;; No words.
  (should-error (nsspell--check-word ""))
  ;; Too many words.
  (should-error (nsspell--check-word "hells bells")))

(ert-deftest test-nsspell-dictionary-p ()
  "Tests the language listing capacity of `nsspell-native'."
  ;; It seems safe enough to assume that English is available.
  (should (equal t (nsspell-dictionary-p "en")))
  ;; But this one is unlikely.
  (should (equal nil (nsspell-dictionary-p "saskquatch"))))
