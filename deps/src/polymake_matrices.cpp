#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_matrices.h"

void polymake_module_add_matrix(jlcxx::Module& polymake)
{

    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "pm_Matrix", jlcxx::julia_type("AbstractMatrix", "Base"))
        .apply<pm::Matrix<int>, pm::Matrix<pm::Integer>, pm::Matrix<pm::Rational>, pm::Matrix<double>>(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type             WrappedT;
                typedef typename decltype(wrapped)::type::value_type elemType;
                wrapped.template constructor<int32_t, int32_t>();
                wrapped.template constructor<int64_t, int64_t>();
                wrapped.template constructor<pm::SparseMatrix<elemType>>();

                wrapped.method("_getindex",
                               [](WrappedT& f, int64_t i, int64_t j) {
                                   return elemType(f(i - 1, j - 1));
                               });
                wrapped.method("_setindex!",
                               [](WrappedT& M, elemType r, int64_t i,
                                  int64_t j) { M(i - 1, j - 1) = r; });
                wrapped.method("rows", &WrappedT::rows);
                wrapped.method("cols", &WrappedT::cols);
                wrapped.method("resize", [](WrappedT& M, int64_t i,
                                            int64_t j) { M.resize(i, j); });

                wrapped.method("take",
                               [](pm::perl::Object p, const std::string& s,
                                  WrappedT& M) { p.take(s) << M; });
                wrapped.method("show_small_obj", [](WrappedT& M) {
                    return show_small_object<WrappedT>(M);
                });
            });
    polymake.method("to_matrix_int", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Matrix<int>>(pv);
    });
    polymake.method("to_matrix_Integer", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Matrix<pm::Integer>>(pv);
    });
    polymake.method("to_matrix_Rational", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Matrix<pm::Rational>>(pv);
    });
    polymake.method("to_matrix_double", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Matrix<double>>(pv);
    });
}
