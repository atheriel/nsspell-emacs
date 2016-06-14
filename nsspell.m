#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <emacs-module.h>

/* Declare mandatory GPL symbol.  */
int plugin_is_GPL_compatible;

/* Move a string from Emacs into C. */
char *
str_from_emacs(emacs_env *env, emacs_value value, ptrdiff_t *size)
{
  env->copy_string_contents(env, value, NULL, size);
  char *str = malloc(*size);
  env->copy_string_contents(env, value, str, size);
  return str;
}

/* Accumulate arguments into a list. */
static emacs_value
create_list(emacs_env *env, ptrdiff_t nargs, emacs_value args[])
{
  emacs_value Qlist = env->intern(env, "list");
  return env->funcall(env, Qlist, nargs, args);
}

static emacs_value
Fcheck_word(emacs_env *env, ptrdiff_t nargs, emacs_value args[], void *data)
{
  // First, we need the spell checker.
  NSSpellChecker *checker = [NSSpellChecker sharedSpellChecker];

  // Turn an Emacs string into a Foundation one.
  
  // TODO: Ensure that the argument is a string.
  ptrdiff_t size = 0;
  char *el_str = str_from_emacs(env, args[0], &size);
  NSString *nsstr = [NSString stringWithUTF8String:el_str]; // Copy!
  NSRange word_range = NSMakeRange(0, size - 1);

  // Ask the spellchecker for suggestions.

  NSArray *suggestions = [checker guessesForWordRange:word_range
  					     inString:nsstr
  					     language:nil
  			       inSpellDocumentWithTag:0];

  ptrdiff_t count = (ptrdiff_t) suggestions.count;

  if (count == 0) { // Return the empty list, if need be.
    return env->intern(env, "nil");
  }

  // Otherwise, manually create an array of strings (in Emacs) from
  // the array of suggestions return from NSSpellChecker.

  emacs_value *rvals = malloc(sizeof(emacs_value) * count);
  int rval_index = 0;

  for (NSString *suggestion in suggestions) {
    const char *cstr = [suggestion UTF8String]; // Shared reference!
    emacs_value estr = env->make_string(env, cstr, strlen(cstr));
    rvals[rval_index] = estr;
    rval_index = rval_index + 1;
  }

  // Clean up.
  
  free(el_str);
  [nsstr release];
  // FIXME: Emacs crashes when I do this... not sure why.
  // [suggestions release];

  // Return a list of suggestions.
  return create_list(env, count, rvals);
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

  DEFUN("nsspell-check-word",
	Fcheck_word, 1, 1,
	"docs.",
	NULL);

#undef DEFUN

  provide (env, "nsspell");
  return 0;
}
