#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_sparsematrix.h"

void polymake_module_add_sparsematrix(jlcxx::Module& polymake)
{
    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>, jlcxx::ParameterList<jlcxx::TypeVar<1>,int>>(
            "pm_SparseMatrix", jlcxx::julia_type("AbstractSparseMatrix", "SparseArrays"))
            .apply_combination<pm::SparseMatrix, pm_VecOrMat_supported::value_type>(
                [](auto wrapped) {
                    typedef typename decltype(wrapped)::type matType;
                    typedef typename decltype(wrapped)::type::value_type elemType;
                    wrapped.template constructor<int32_t, int32_t>();
                    wrapped.template constructor<int64_t, int64_t>();
                    wrapped.method("_getindex",
                        [](matType& M, int64_t i, int64_t j) {
                            return elemType(M(i - 1, j - 1));
                    });
                    wrapped.method("_setindex!",
                        [](matType& M, elemType r, int64_t i,
                        int64_t j) {
                            M(i - 1, j - 1) = r;
                    });
                    wrapped.method("rows", &matType::rows);
                    wrapped.method("cols", &matType::cols);
                    wrapped.method("nzindices", [](matType& S) {
                        return Array<Set<int32_t>>(pm::rows(pm::index_matrix(S)));
                    });
                    wrapped.method("resize!", [](matType& M, int64_t i,
                                                int64_t j) { M.resize(i, j); });
                    wrapped.method("take",
                                   [](pm::perl::Object p, const std::string& s,
                                      matType& M) { p.take(s) << M; });
                    wrapped.method("show_small_obj", [](matType& S) {
                        return show_small_object<matType>(S);
                    });
            });
    polymake.method("to_pm_sparsematrix_Rational",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseMatrix<pm::Rational>>(pv);
    });
    polymake.method("to_pm_sparsematrix_Integer",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseMatrix<pm::Integer>>(pv);
    });
    polymake.method("to_pm_sparsematrix_int",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseMatrix<int>>(pv);
    });
    polymake.method("to_pm_sparsematrix_double",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::SparseMatrix<double>>(pv);
    });
}
