#

#if 1
#warning See first condition
#endif

#if 0
#warning second condition
#endif

#if 1
#warning See third condition
#else
#warning third else
#endif

#if 0
#warning forth condition
#else
#warning See forth else
#endif

#if 0
#warning fifth condition
#elif 1
#warning See fifth elif 
#else
#warning fifth else
#endif

#if 0
#warning sixth condition
#elif 0
#warning sixth elif 
#else
#warning See sixth else
#endif

#line 655 "flakewad.h"

#warning @ flakewad.h:656

#if 1
#if 1
#warning See seventh nested if
#else
#warning seventh nested else
#endif
#endif

#if 1
#if 0
#warning eigth nested if
#else
#warning See eigth nested else
#endif
#endif

#if 1
#if 0
#warning ninth nested if
#elif 1
#warning See ninth nested elif
#else
#warning ninth nested else
#endif
#endif

#if 1
#if 0
#warning tenth nested if
#elif 0
#warning tenth nested elif
#else
#warning See tenth nested else
#endif
#endif

#if 1
#line
#else
#line
#endif

#if 1
#error Error yes
#else
#error Error No
#endif

#if 0
#include "include1.h"
#else
#include "include2.h"
#endif

#if 1
#warning 11
#else
#warning 11
#else
#warning 11
#endif

#define TEST1_MACRO

#if defined TEST1_MACRO
#warning 1. "TEST1_MACRO" is defined
#endif

#if defined ( TEST1_MACRO )
#warning 2. "TEST1_MACRO" is defined
#endif

#if !defined TEST1_MACRO
#warning 3. "TEST1_MACRO" is NOT defined
#else
#warning 3. "TEST1_MACRO" is defined
#endif

#if !defined TEST1_MACRO
#warning 4. "TEST1_MACRO" is NOT defined
#else
#warning 4. "TEST1_MACRO" is defined
#endif

#ifdef TEST1_MACRO
#warning 5. "TEST1_MACRO" is defined
#endif

#ifndef TEST1_MACRO
#warning 6. "TEST1_MACRO" is NOT defined
#else
#warning 6. "TEST1_MACRO" is defined
#endif

#else
#warning #else is an error
#endif

#elif 1
#warning #elif is an error
#endif





