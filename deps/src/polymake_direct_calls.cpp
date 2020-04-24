#include "polymake_includes.h"

#include "polymake_type_modules.h"

template<typename Scalar>
pm::Vector<Scalar> direct_call_solve_LP(
    const pm::Matrix<Scalar>& inequalities,
    const pm::Matrix<Scalar>& equalities,
    const pm::Vector<Scalar>& objective,
    bool                      maximize)
{
    try {
        auto solution = polymake::polytope::solve_LP(inequalities, equalities, objective, maximize);
        return solution.solution;
    } catch (...) {
        return pm::Vector<Scalar>();
    }
}


void polymake_module_add_direct_calls(jlcxx::Module& polymake)
{
    polymake.method("direct_call_solve_LP", &direct_call_solve_LP<pm::Rational>);
    polymake.method("direct_call_solve_LP_float", &direct_call_solve_LP<double>);
}
