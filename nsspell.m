#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <emacs-module.h>

/* Declare mandatory GPL symbol.  */
int plugin_is_GPL_compatible;

static emacs_value
create_list(emacs_env *env, ptrdiff_t nargs, emacs_value args[]);

/* Move a string from Emacs into Foundation. */
NSString *
nsstr_from_emacs(emacs_env *env, emacs_value value, ptrdiff_t *size)
{
  env->copy_string_contents(env, value, NULL, size);
  char *str = malloc(*size);
  env->copy_string_contents(env, value, str, size);
  NSString *nsstr = [NSString stringWithUTF8String:str]; // Copy!
  free(str);
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

  // Turn an Emacs string into a Foundation one.
  
  // TODO: Ensure that the argument is a string.
  ptrdiff_t size = 0;
  NSString *nsstr = nsstr_from_emacs(env, args[0], &size);
  NSRange word_range = NSMakeRange(0, size - 1);

  // Ask the spellchecker for suggestions.

  NSArray *suggestions = [checker guessesForWordRange:word_range
  					     inString:nsstr
  					     language:nil
  			       inSpellDocumentWithTag:0];

  return str_list_from_ns(env, suggestions);
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

  DEFUN("nsspell-check-word",
	Fcheck_word, 1, 1,
	"docs.",
	NULL);

#undef DEFUN

  provide (env, "nsspell");
  return 0;
}
