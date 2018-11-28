#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_vectors.h"

void polymake_module_add_vector(jlcxx::Module& polymake)
{

    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "pm_Vector", jlcxx::julia_type("AbstractVector", "Base"))
        .apply<pm::Vector<pm::Integer>, pm::Vector<pm::Rational>>(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type             WrappedT;
                typedef typename decltype(wrapped)::type::value_type elemType;
                wrapped.template constructor<int32_t>();
                wrapped.template constructor<int64_t>();
                wrapped.method("_getindex", [](WrappedT& V, int64_t n) {
                    return elemType(V[n - 1]);
                });
                wrapped.method("_setindex!",
                               [](WrappedT& V, elemType val, int64_t n) {
                                   V[n - 1] = val;
                               });
                wrapped.method("length", &WrappedT::size);
                wrapped.method("resize!",
                               [](WrappedT& V, int64_t sz) { V.resize(sz); });

                wrapped.method("take",
                               [](pm::perl::Object p, const std::string& s,
                                  WrappedT& V) { p.take(s) << V; });
                wrapped.method("show_small_obj", [](WrappedT& V) {
                    return show_small_object<WrappedT>(V);
                });
            });
    polymake.method("to_vector_Integer", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Vector<pm::Integer>>(pv);
    });
    polymake.method("to_vector_Rational", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Vector<pm::Rational>>(pv);
    });
}
