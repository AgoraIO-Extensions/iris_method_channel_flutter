#ifndef __IRIS_KEYWORD_H__
#define __IRIS_KEYWORD_H__

#include <stdint.h>

#if defined(_MSC_VER)
typedef __int64 int64;
typedef unsigned __int64 uint64;
#elif (defined(__LONG_WIDTH__) && __LONG_WIDTH__ == 8)                         \
    || (defined(__SIZEOF_LONG__) && __SIZEOF_LONG__ == 8)
typedef signed long int64;
typedef unsigned long uint64;
#else
typedef signed long long int64;
typedef unsigned long long uint64;
#endif

#endif