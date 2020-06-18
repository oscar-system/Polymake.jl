#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_type_modules.h"


tparametric1 polymake_module_add_array(jlcxx::Module& polymake)
{

    auto type = polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "Array", jlcxx::julia_type("AbstractVector", "Base"));

        type.apply<pm::Array<pm::Int>, pm::Array<pm::Integer>,
               pm::Array<pm::Rational>,
               pm::Array<std::string>, pm::Array<pm::Set<pm::Int>>,
               pm::Array<pm::Array<pm::Int>>,
               pm::Array<pm::Array<pm::Integer>>,
               pm::Array<pm::Array<pm::Rational>>,
               pm::Array<std::pair<pm::Int, pm::Int>>,
               pm::Array<std::list<std::pair<pm::Int, pm::Int>>>,
               pm::Array<pm::Matrix<pm::Integer>>>([](auto wrapped) {
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
        })
        .apply<pm::Array<pm::perl::BigObject>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type WrappedT;
            typedef pm::perl::BigObject elemType;

            wrapped.template constructor<int64_t>();

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
        });

    polymake.method("to_array_int", [](const pm::perl::PropertyValue& pv) {
        return to_SmallObject<pm::Array<pm::Int>>(pv);
    });
    polymake.method("to_array_integer",
                    [](const pm::perl::PropertyValue& pv) {
                        return to_SmallObject<pm::Array<pm::Integer>>(pv);
                    });
    polymake.method("to_array_string", [](const pm::perl::PropertyValue& pv) {
        return to_SmallObject<pm::Array<std::string>>(pv);
    });
    polymake.method("to_array_array_int",
                    [](const pm::perl::PropertyValue& pv) {
                        return to_SmallObject<pm::Array<pm::Array<pm::Int>>>(pv);
                    });
    polymake.method(
        "to_array_array_integer", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::Array<pm::Integer>>>(pv);
        });
    polymake.method(
        "to_array_array_rational", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::Array<pm::Rational>>>(pv);
        });
    polymake.method(
        "to_array_set_int", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::Set<pm::Int>>>(pv);
        });
    polymake.method(
        "to_array_pair_int_int", [](const pm::perl::PropertyValue& pv){
                return to_SmallObject<pm::Array<std::pair<pm::Int, pm::Int>>>(pv);
        });
    polymake.method(
            "to_array_list_pair_int_int", [](const pm::perl::PropertyValue& pv){
                return to_SmallObject<pm::Array<std::list<std::pair<pm::Int, pm::Int>>>>(pv);
            });
    polymake.method(
        "to_array_matrix_integer", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::Matrix<pm::Integer>>>(pv);
        });
    polymake.method(
        "to_array_bigobject", [](const pm::perl::PropertyValue& pv) {
            return to_SmallObject<pm::Array<pm::perl::BigObject>>(pv);
        });
    return type;
}
