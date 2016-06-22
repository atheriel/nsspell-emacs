-*- mode: gfm; fill-column: 80 -*-

`nsspell` is an Emacs package for interacting with the macOS spell checker. It
makes use of the new dynamic module system for Emacs 25 in order to interface
with the relevant Objective-C APIs.

The project is in an early, proof-of-concept stage. For those hoping to see a
fully-formed, drop-in replacement for `flyspell`, prepare to be disappointed.

One observation I will make is that that the Objective-C API is so very
different from `ispell`, `aspell`, or `hunspell` that it makes writing a simple
backend for `ispell.el` very difficult. However, I think that it also has the
potential to make a more versatile and performant spell checker, since it is
possible to check more than one word at a time.

## Examples

The API currently looks as follows:

``` emacs-lisp
;; Check that a Canadian English dictionary is available.
(nsspell-dictionary-p "en_CA")
	=> t

;; Low-level spell checking interface.
(nsspell--check-word "piano")
	=> t
(nsspell--check-word "helli" "en_CA")
	=> ("hello" "hell" "hells" "belli" "elli")

;; List suggestions for any word.
(nsspell--suggestions-for "helli")
	=> ("hello" "hell" "hells" "belli" "elli")
(nsspell--suggestions-for "hello" "en_CA")
	=> ("hell" "hells" "hallo" "jello" "hellos" ...)
```

Notice that it is happy to make suggestions for words that are notionally
spelled correctly...

## Installation

This package is not available on MELPA or any of the other Emacs package
repositories. I am unsure how/when/if dynamic modules containing native code
would be distributed through these repositories. For now, you will have to clone
this repository and build the artifact yourself, and then make it available in
Emacs's load path.

There is a Makefile provided, so you should be able to run a simple `make` to
build the dynamic module. There is also an easy-to-use `make test` target that
will check if it is working.

In order to make this package work, you need (a) to be on Mac OS X, and (b) to
have a version of Emacs that supports dynamic modules. If you are unsure of the
latter, you can check whether the symbol `module-file-suffix` is bound and not
`nil`, or run the following `make` target from this repository:

``` shell
$ make module-support-test
```

which will echo something brief but helpful.

If your version of Emacs does _not_ support dynamic modules, you will need to
install one that does. The development release 25.0.95 does have optional
support, if you pass the `--with-modules` flag to the `./configure` script
during compilation.

For those that are intimidated by the thought of compiling Emacs themselves: I
have
[submitted a pull request to Homebrew](https://github.com/Homebrew/homebrew-core/pull/2263)
to make building a dynamic module-supporting version of Emacs easier.
