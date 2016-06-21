#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <emacs-module.h>

/* Declare mandatory GPL symbol.  */
int plugin_is_GPL_compatible;

static emacs_value create_list(emacs_env *env, ptrdiff_t nargs, emacs_value args[]);
static bool stringp(emacs_env *env, emacs_value value);

/* Move a string from Emacs into Foundation. */
NSString *
nsstr_from_emacs(emacs_env *env, emacs_value value, ptrdiff_t *size)
{
  ptrdiff_t rsize = 0;
  env->copy_string_contents(env, value, NULL, &rsize);
  char *str = malloc(rsize);
  env->copy_string_contents(env, value, str, &rsize);
  NSString *nsstr = [NSString stringWithUTF8String:str]; // Copy!
  free(str);

  // Return the size if the user asks for it.
  if (size != NULL) {
    *size = rsize;
  }

  return nsstr;
}

static emacs_value
str_list_from_ns(emacs_env *env, NSArray *strings)
{
  // FIXME: Do we need to check that it's an NSArray<NSString>?

  ptrdiff_t count = (ptrdiff_t) strings.count;

  // Return the empty list, if need be.
  if (count == 0) {
    return env->intern(env, "nil");
  }

  // Otherwise, manually create an array of strings (as an Emacs list) from
  // the array of strings.
  emacs_value *rvals = malloc(sizeof(emacs_value) * count);
  int rval_index = 0;

  for (NSString *string in strings) {
    const char *cstr = [string UTF8String]; // Shared reference!
    emacs_value estr = env->make_string(env, cstr, strlen(cstr));
    rvals[rval_index] = estr;
    rval_index = rval_index + 1;
  }

  // FIXME: Emacs crashes when I do this... not sure why.
  // [strings release];

  // Return a list of strings.
  return create_list(env, count, rvals);
}

static emacs_value
Fcheck_word(emacs_env *env, ptrdiff_t nargs, emacs_value args[], void *data)
{
  // First, we need the spell checker.
  NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];

  // Signal errors if the arguments are not strings.
  if (!stringp(env, args[0])) {
    emacs_value error_symbol = env->intern(env, "wrong-type-argument");
    emacs_value error_data[2] = { env->intern(env, "stringp"),
				  args[0] };
    env->non_local_exit_signal(env, error_symbol,
			       create_list(env, 2, error_data));
  }
  if (nargs > 1 && !stringp(env, args[1])) {
    emacs_value error_symbol = env->intern(env, "wrong-type-argument");
    emacs_value error_data[2] = { env->intern(env, "stringp"),
				  args[1] };
    env->non_local_exit_signal(env, error_symbol,
			       create_list(env, 2, error_data));
  }

  // Turn an Emacs string into a Foundation one.
  ptrdiff_t size = 0;
  NSString *nsstr = nsstr_from_emacs(env, args[0], &size);

  // Signal an error if the string contains no content.
  if (size < 1) {
    emacs_value error_symbol = env->intern(env, "no-words-in-string");
    emacs_value error_data[1] = { args[0] };
    env->non_local_exit_signal(env, error_symbol,
			       create_list(env, 1, error_data));
  }

  NSString *lang;
  if (nargs > 1) {
    lang = nsstr_from_emacs(env, args[1], NULL);
  } else {
    lang = nil; // When nil, the checker will use the system default.
  }

  NSInteger count = [checker countWordsInString:nsstr language:lang];

  // Signal an error when we have more than one word.
  if (count != 1) {
    emacs_value error_symbol = env->intern(env, "wrong-number-of-words");
    emacs_value error_data[2] = { env->make_integer(env, 1),
				  env->make_integer(env, count) };
    env->non_local_exit_signal(env, error_symbol,
			       create_list(env, 2, error_data));
  }

  // Check spelling of the strings.
  NSInteger checked = -1;
  NSRange error_range = [checker checkSpellingOfString:nsstr
					    startingAt:0
					      language:lang
						  wrap:NO
				inSpellDocumentWithTag:0
					     wordCount:&checked];

  // The API seems to return a large number if it checks the whole
  // string without issue. In that case, return t.
  if (error_range.location >= [nsstr length]) {
    return env->intern(env, "t");
  }

  // Otherwise, ask the spellchecker for suggestions.

  NSArray *suggestions = [checker guessesForWordRange:error_range
                                             inString:nsstr
                                             language:lang
                               inSpellDocumentWithTag:0];

  [nsstr release];
  [lang release];

  return str_list_from_ns(env, suggestions);
}

static emacs_value
Flist_languages(emacs_env *env, ptrdiff_t nargs, emacs_value args[], void *data)
{
  NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];
  NSArray *languages = checker.availableLanguages;
  return str_list_from_ns(env, languages);
}

/* Check for the string type. */
static bool
stringp(emacs_env *env, emacs_value value)
{
  emacs_value string = env->intern(env, "string");
  return env->eq(env, env->type_of(env, value), string);
}

/* Accumulate arguments into a list. */
static emacs_value
create_list(emacs_env *env, ptrdiff_t nargs, emacs_value args[])
{
  emacs_value Qlist = env->intern(env, "list");
  return env->funcall(env, Qlist, nargs, args);
}

/* Bind NAME to FUN.  */
static void
bind_function(emacs_env *env, const char *name, emacs_value Sfun)
{
  emacs_value Qfset = env->intern(env, "fset");
  emacs_value Qsym = env->intern(env, name);
  emacs_value args[] = { Qsym, Sfun };
  env->funcall(env, Qfset, 2, args);
}

/* Provide FEATURE to Emacs.  */
static void
provide (emacs_env *env, const char *feature)
{
  emacs_value Qfeat = env->intern(env, feature);
  emacs_value Qprovide = env->intern(env, "provide");
  emacs_value args[] = { Qfeat };
  env->funcall(env, Qprovide, 1, args);
}

int
emacs_module_init (struct emacs_runtime *ert)
{
  emacs_env *env = ert->get_environment(ert);

#define DEFUN(lsym, csym, amin, amax, doc, data) \
  bind_function (env, lsym, env->make_function(env, amin, amax, csym, doc, data))

  DEFUN("nsspell--check-word",
        Fcheck_word, 1, 2,
        "List suggestions for WORD, optionally for LANGUAGE, from the \
OS X spellchecker.\
\\(fn WORD [LANGUAGE])",
        NULL);
  DEFUN("nsspell--list-languages",
        Flist_languages, 0, 0,
        "List available languages for the OS X spell checker.\
\\(fn)",
        NULL);

#undef DEFUN

  provide (env, "nsspell-native");
  return 0;
}
