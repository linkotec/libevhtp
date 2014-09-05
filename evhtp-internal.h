#ifndef __EVHTP_INTERNAL_H__
#define __EVHTP_INTERNAL_H__

#ifdef EVHTP_HAS_VISIBILITY_HIDDEN
#define __visible   __attribute__((visibility("default")))
#define EXPORT_SYMBOL(x) typeof(x)(x)__visible
#else
#define EXPORT_SYMBOL(n)
#endif

#ifndef TAILQ_FOREACH_SAFE
#define TAILQ_FOREACH_SAFE(var, head, field, tvar)        \
    for ((var) = TAILQ_FIRST((head));                     \
         (var) && ((tvar) = TAILQ_NEXT((var), field), 1); \
         (var) = (tvar))
#endif

#if defined(_WIN32) || defined(_WIN64)
#ifndef atoll
#define atoll _atoi64
#endif

#ifndef inline
#define inline __inline
#endif

#if defined(_WIN64)
typedef __int64 ssize_t;
#else
typedef long ssize_t;
#endif

#ifndef snprintf
#define snprintf _snprintf
#endif

#ifndef strcasecmp
#define strcasecmp _stricmp
#endif

#ifndef strncasecmp
#define strncasecmp _strnicmp
#endif
#endif

#endif

