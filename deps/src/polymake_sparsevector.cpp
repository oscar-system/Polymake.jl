#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_sparsevector.h"

void polymake_module_add_sparsevector(jlcxx::Module& polymake)
{
    polymake
    .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>, jlcxx::ParameterList<jlcxx::TypeVar<1>,int>>(
        "SparseVector", jlcxx::julia_type("AbstractSparseVector", "SparseArrays"))
        .apply_combination<pm::SparseVector, VecOrMat_supported::value_type>(
            [](auto wrapped) {
                    typedef typename decltype(wrapped)::type vecType;
                    typedef typename decltype(wrapped)::type::value_type elemType;
                    wrapped.template constructor<vecType>();
                    wrapped.template constructor<pm::Vector<elemType>>();
                    wrapped.template constructor<int32_t>();
                    wrapped.template constructor<int64_t>();
                    wrapped.method("_getindex",
                        [](vecType& V, int64_t i) {
                            return elemType(V[i - 1]);
                    });
                    wrapped.method("_setindex!",
                        [](vecType& V, elemType r, int64_t i) {
                            V[i - 1] = r;
                    });
                    wrapped.method("length", &vecType::dim);
                    wrapped.method("resize!",
                                   [](vecType& V, int64_t sz) { V.resize(sz); });
                    wrapped.method("show_small_obj", [](vecType& S) {
                        return show_small_object<vecType>(S);
                    });
            });
    polymake.method("to_sparsevector_rational",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseVector<pm::Rational>>(pv);
    });
    polymake.method("to_sparsevector_integer",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseVector<pm::Integer>>(pv);
    });
    polymake.method("to_sparsevector_int",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseVector<pm::Int>>(pv);
    });
    polymake.method("to_sparsevector_double",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseVector<double>>(pv);
    });
}
