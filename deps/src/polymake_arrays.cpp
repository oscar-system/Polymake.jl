#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_arrays.h"


void polymake_module_add_array(jlcxx::Module& polymake)
{

    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "pm_Array", jlcxx::julia_type("AbstractVector", "Base"))
        .apply<pm::Array<int32_t>, pm::Array<long>, pm::Array<pm::Integer>,
               pm::Array<std::string>, pm::Array<pm::Set<int32_t>>,
               pm::Array<pm::Array<int32_t>>, pm::Array<pm::Array<long>>,
               pm::Array<pm::Array<pm::Integer>>,
               pm::Array<pm::Matrix<pm::Integer>>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type             WrappedT;
            typedef typename decltype(wrapped)::type::value_type elemType;

            wrapped.template constructor<int32_t>();
            wrapped.template constructor<int32_t, elemType>();
            wrapped.template constructor<int64_t>();
            wrapped.template constructor<int64_t, elemType>();

            wrapped.method("_getindex", [](const WrappedT& A, int64_t n) {
                return elemType(A[static_cast<long>(n) - 1]);
            });
            wrapped.method("_setindex!",
                           [](WrappedT& A, const elemType& val, int64_t n) {
                               A[static_cast<long>(n) - 1] = val;
                           });
            wrapped.method("length", &WrappedT::size);
            wrapped.method("resize!", [](WrappedT& A, int64_t newsz) {
                A.resize(static_cast<long>(newsz));
                return A;
            });
            wrapped.method("resize!", [](WrappedT& A, int32_t newsz) {
                A.resize(static_cast<long>(newsz));
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
                           [](pm::perl::Object p, const std::string& s,
                              WrappedT& A) { p.take(s) << A; });
        })
        .apply<pm::Array<pm::perl::Object>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type             WrappedT;
            typedef perl::Object elemType;

            wrapped.template constructor<int32_t>();
            wrapped.template constructor<int64_t>();

            wrapped.method("_getindex", [](const WrappedT& A, int64_t n) {
                return elemType(A[static_cast<long>(n) - 1]);
            });
            wrapped.method("_setindex!",
                           [](WrappedT& A, const elemType& val, int64_t n) {
                               A[static_cast<long>(n) - 1] = val;
                           });
            wrapped.method("length", &WrappedT::size);
            wrapped.method("resize!", [](WrappedT& A, int64_t newsz) {
                A.resize(static_cast<long>(newsz));
                return A;
            });
            wrapped.method("resize!", [](WrappedT& A, int32_t newsz) {
                A.resize(static_cast<long>(newsz));
                return A;
            });
        });

    polymake.method("to_array_int32", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<int32_t>>(pv);
    });
    polymake.method("to_array_int64", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<long>>(pv);
    });
    polymake.method("to_array_Integer", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<pm::Integer>>(pv);
    });
    polymake.method("to_array_string", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<std::string>>(pv);
    });
    polymake.method("to_array_array_int32", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<pm::Array<int32_t>>>(pv);
    });
    polymake.method("to_array_array_int64", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<pm::Array<long>>>(pv);
    });
    polymake.method("to_array_array_Integer", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<pm::Array<pm::Integer>>>(pv);
    });
    polymake.method("to_array_set_int32", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Array<pm::Set<int32_t>>>(pv);
    });
    polymake.method(
        "to_array_matrix_Integer", [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::Array<pm::Matrix<pm::Integer>>>(pv);
        });
    polymake.method(
        "to_array_perl_object", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::perl::Object>>(pv);
        });
}
