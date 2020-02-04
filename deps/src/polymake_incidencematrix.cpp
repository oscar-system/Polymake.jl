#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_incidencematrix.h"

void polymake_module_add_incidencematrix(jlcxx::Module& polymake)
{
    polymake.add_type<pm::NonSymmetric>("NonSymmetric");
    polymake.add_type<pm::Symmetric>("Symmetric");
    polymake
    .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>, jlcxx::ParameterList<bool,int>>(
        "IncidenceMatrix", jlcxx::julia_type("AbstractSparseMatrix", "SparseArrays"))
        .apply_combination<pm::IncidenceMatrix, jlcxx::ParameterList<pm::NonSymmetric,pm::Symmetric>>(
            [](auto wrapped) {
        typedef typename decltype(wrapped)::type WrappedT;
        wrapped.template constructor<int64_t, int64_t>();
        wrapped.method("_getindex",
            [](WrappedT& M, int64_t i, int64_t j) {
                return bool(M(i - 1, j - 1));
        });
        wrapped.method("_setindex!",
            [](WrappedT& M, bool r, int64_t i,
            int64_t j) {
                M(i - 1, j - 1) = r;
        });
        wrapped.method("nrows", &WrappedT::rows);
        wrapped.method("_row", [](WrappedT& M, int64_t i) { return pm::Set<pm::Int>(M.row(i - 1)); });
        wrapped.method("ncols", &WrappedT::cols);
        wrapped.method("_col", [](WrappedT& M, int64_t i) { return pm::Set<pm::Int>(M.col(i - 1)); });
        wrapped.method("_resize!", [](WrappedT& M, int64_t i,
                                    int64_t j) { M.resize(i, j); });
        wrapped.method("take",
                       [](pm::perl::BigObject p, const std::string& s,
                          WrappedT& M) { p.take(s) << M; });

        wrapped.method("show_small_obj", [](WrappedT& S) {
            return show_small_object<WrappedT>(S);
        });
    });
    polymake.method("to_incidencematrix_nonsymmetric", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::IncidenceMatrix<pm::NonSymmetric>>(pv);
    });
    polymake.method("to_incidencematrix_symmetric", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::IncidenceMatrix<pm::Symmetric>>(pv);
    });
}
