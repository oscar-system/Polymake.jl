#ifndef POLYMAKE_JLCXX
#define POLYMAKE_JLCXX

// This must be the very first include

// workaround xcode 11.4 issue until upstream fix arrives in xcode:
// https://github.com/llvm/llvm-project/commit/2464d8135e
//
// first include __config from libc++, then override typeinfo flag
// to force use of address as hash instead of hashing the string

#if defined(__APPLE__) && defined(FORCE_XCODE_TYPEINFO_MERGED)
#include <__config>
#if defined(_LIBCPP_HAS_MERGED_TYPEINFO_NAMES_DEFAULT) && \
    _LIBCPP_HAS_MERGED_TYPEINFO_NAMES_DEFAULT == 0
#undef _LIBCPP_HAS_MERGED_TYPEINFO_NAMES_DEFAULT
#define _LIBCPP_HAS_MERGED_TYPEINFO_NAMES_DEFAULT 1
#endif
#endif

#include "jlcxx/jlcxx.hpp"

#endif
