#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_type_modules.h"


tparametric1 polymake_module_add_pair(jlcxx::Module& polymake)
{

    auto type = polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>, jlcxx::TypeVar<2>>>(
            "Pair", jlcxx::julia_type("Tuple", "Base"));

        type.apply<std::pair<pm::Integer,pm::Integer>>[](auto wrapped) {
            typedef typename decltype(wrapped)::type             WrappedT;
            typedef typename decltype(wrapped)::type::value_type elemType;

            wrapped.template constructor<int64_t>();
            wrapped.template constructor<int64_t>(int64_t, int64_t);

            wrapped.method("_getindex", [](const WrappedT& P, int64_t n) {
                return elemType(P.getIndex(static_cast<pm::Int>(n) - 1));
            });

            wrapped.method("first", [](WrappedT& P) {
                return P.first();
            });

            wrapped.method("last", [](WrappedT& P) {
                return P.last();
            });
        })

    polymake.method("to_pair_int", [](const pm::perl::PropertyValue& pv) {
        return to_SmallObject<std::pair<pm::Int>>(pv);
    });

    return type;
}
