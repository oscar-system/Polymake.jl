#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_incidencematrix.h"

void polymake_module_add_incidencematrix(jlcxx::Module& polymake)
{
    polymake
        .add_type<pm::IncidenceMatrix>("pm_IncidenceMatrix",
                                jlcxx::julia_type("AbstractMatrix", "Base"))
                                .apply_combination<pm::IncidenceMatrix, pm_VecOrMat_supported::value_type>(
                                    [](auto wrapped) {
        .constructor<int32_t, int32_t>()
        .constructor<int64_t, int64_t>()
        .method("_getindex",
            [](pm::IncidenceMatrix& M, int64_t i, int64_t j) {
                return elemType(M(i - 1, j - 1));
        })
        .method("_setindex!",
            [](pm::IncidenceMatrix& M, elemType r, int64_t i,
            int64_t j) {
                M(i - 1, j - 1) = r;
        })
        .method("rows", &pm::IncidenceMatrix::rows)
        .method("cols", &pm::IncidenceMatrix::cols)
        .method("resize", [](pm::IncidenceMatrix& M, int64_t i,
                                    int64_t j) { M.resize(i, j); })
        .method("take",
                       [](pm::perl::Object p, const std::string& s,
                          pm::IncidenceMatrix& M) { p.take(s) << M; })
        .method("show_small_obj", [](pm::IncidenceMatrix& S) {
            return show_small_object<pm::IncidenceMatrix>(S);
        });
    }
}
