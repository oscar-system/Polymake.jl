#ifndef POLYMAKE_WRAP_ARRAY
#define POLYMAKE_WRAP_ARRAY

#include "jlcxx/jlcxx.hpp"

using tparametric1 = jlcxx::TypeWrapper<jlcxx::Parametric<jlcxx::TypeVar<1>>>;
tparametric1 polymake_module_add_array(jlcxx::Module& polymake);

#endif
