(require 'nsspell)

(ert-deftest test-nsspell--check-word ()
  "Tests word checking in `nsspell-native'."
  (should (equal t (nsspell--check-word "cello")))
  (should (equal t (nsspell--check-word "cello" "en_GB")))
  ;; Not currently working correctly:
  ;; (should-error (nsspell--check-word ""))
  ;; (should-error (nsspell--check-word "hells bells"))
  )

(ert-deftest test-nsspell-dictionary-p ()
  "Tests the language listing capacity of `nsspell-native'."
  ;; It seems safe enough to assume that English is available.
  (should (equal t (nsspell-dictionary-p "en")))
  ;; But this one is unlikely.
  (should (equal nil (nsspell-dictionary-p "saskquatch"))))
