EMACS_ROOT ?= ./emacs-25.0.95
FRAMEWORKS = -framework Foundation -framework AppKit

nsspell-native.so: nsspell-native.m
	clang -g -shared $(FRAMEWORKS) -I$(EMACS_ROOT)/src -o $@ $<

$(EMACS_ROOT)/src/emacs-module.h:
	brew unpack --patch emacs --devel

test: nsspell-tests.el
	emacs -batch -l ert -L . -l nsspell-tests.el -f ert-run-tests-batch-and-exit

.PHONY: test
