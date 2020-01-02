#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_incidencematrix.h"

void polymake_module_add_incidencematrix(jlcxx::Module& polymake)
{
    polymake.add_type<pm::NonSymmetric>("pm_NonSymmetric");
    polymake.add_type<pm::Symmetric>("pm_Symmetric");
    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_IncidenceMatrix",
                                jlcxx::julia_type("AbstractMatrix", "Base"))
                                .apply_combination<pm::IncidenceMatrix, jlcxx::ParameterList<pm::NonSymmetric,pm::Symmetric>>(
                                    [](auto wrapped) {
        typedef typename decltype(wrapped)::type WrappedT;
        wrapped.template constructor<int32_t, int32_t>();
        wrapped.template constructor<int64_t, int64_t>();
        wrapped.method("_getindex",
            [](WrappedT& M, int64_t i, int64_t j) {
                return pm::Integer(M(i - 1, j - 1));
        });
        wrapped.method("_setindex!",
            [](WrappedT& M, int64_t r, int64_t i,
            int64_t j) {
                M(i - 1, j - 1) = r;
        });
        wrapped.method("rows", &WrappedT::rows);
        wrapped.method("cols", &WrappedT::cols);
        wrapped.method("resize!", [](WrappedT& M, int64_t i,
                                    int64_t j) { M.resize(i, j); });
        wrapped.method("take",
                       [](pm::perl::Object p, const std::string& s,
                          WrappedT& M) { p.take(s) << M; });
        wrapped.method("show_small_obj", [](WrappedT& S) {
            return show_small_object<WrappedT>(S);
        });
    });
    polymake.method("to_incidencematrix_NonSymmetric", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::IncidenceMatrix<pm::NonSymmetric>>(pv);
    });
    polymake.method("to_incidencematrix_Symmetric", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::IncidenceMatrix<pm::Symmetric>>(pv);
    });
}
