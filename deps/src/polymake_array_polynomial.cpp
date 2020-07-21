#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_type_modules.h"

void polymake_module_add_array_polynomial(jlcxx::Module& polymake, tparametric1 array_type)
{
    array_type
        .apply<pm::Array<pm::Polynomial<pm::Rational,long>>,
               pm::Array<pm::Polynomial<pm::Integer,long>>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type             WrappedT;
            typedef typename decltype(wrapped)::type::value_type elemType;

            wrapped.template constructor<int64_t>();
            wrapped.template constructor<int64_t, elemType>();

            wrapped.method("_getindex", [](const WrappedT& A, int64_t n) {
                return elemType(A[static_cast<pm::Int>(n) - 1]);
            });
            wrapped.method("_setindex!",
                           [](WrappedT& A, const elemType& val, int64_t n) {
                               A[static_cast<pm::Int>(n) - 1] = val;
                           });
            wrapped.method("length", &WrappedT::size);
            wrapped.method("resize!", [](WrappedT& A, int64_t newsz) {
                A.resize(static_cast<pm::Int>(newsz));
                return A;
            });

            wrapped.method("append!", [](WrappedT& A, WrappedT& B) {
                A.append(B);
                return A;
            });
            wrapped.method("fill!", [](WrappedT& A, const elemType& x) {
                A.fill(x);
                return A;
            });
            wrapped.method("show_small_obj", [](const WrappedT& A) {
                return show_small_object<WrappedT>(A);
            });
            wrapped.method("take",
                           [](pm::perl::BigObject p, const std::string& s,
                              WrappedT& A) { p.take(s) << A; });
        });
    polymake.method(
        "to_array_polynomial_integer_int", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::Polynomial<pm::Integer,long>>>(pv);
        });
    polymake.method(
        "to_array_polynomial_rational_int", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::Polynomial<pm::Rational,long>>>(pv);
        });
}
