#ifndef POLYMAKE_TYPE_MODULES
#define POLYMAKE_TYPE_MODULES

#include "polymake_jlcxx.h"

using tparametric1 = jlcxx::TypeWrapper<jlcxx::Parametric<jlcxx::TypeVar<1>>>;

tparametric1 polymake_module_add_array(jlcxx::Module& polymake);
void polymake_module_add_array_polynomial(jlcxx::Module& polymake, tparametric1 arrayt);

void polymake_module_add_bigobject(jlcxx::Module& polymake);
void polymake_module_add_direct_calls(jlcxx::Module&);
void polymake_module_add_incidencematrix(jlcxx::Module& polymake);
void polymake_module_add_integer(jlcxx::Module& polymake);
void polymake_module_add_matrix(jlcxx::Module& polymake);
void polymake_module_add_polynomial(jlcxx::Module& polymake);
void polymake_module_add_rational(jlcxx::Module& polymake);
void polymake_module_add_pairs(jlcxx::Module& polymake);
void polymake_module_add_set(jlcxx::Module& polymake);
void polymake_module_add_sparsematrix(jlcxx::Module& polymake);
void polymake_module_add_sparsevector(jlcxx::Module& polymake);
void polymake_module_add_tropicalnumber(jlcxx::Module& polymake);
void polymake_module_add_type_translations(jlcxx::Module&);
void polymake_module_add_vector(jlcxx::Module& polymake);

#endif
