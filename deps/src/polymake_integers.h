#ifndef POLYMAKE_WRAP_INTEGER
#define POLYMAKE_WRAP_INTEGER

#include "jlcxx/jlcxx.hpp"

void        polymake_module_add_integer(jlcxx::Module& polymake);
pm::Integer new_integer_from_bigint(jl_value_t*);

#endif
