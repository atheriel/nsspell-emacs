EMACS_ROOT ?= ./emacs-25.0.95
FRAMEWORKS = -framework Foundation -framework AppKit

nsspell.so: nsspell.m
	clang -g -shared $(FRAMEWORKS) -I$(EMACS_ROOT)/src -o $@ $<

