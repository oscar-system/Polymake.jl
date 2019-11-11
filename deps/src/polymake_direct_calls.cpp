#include "polymake_includes.h"

#include "polymake_direct_calls.h"

auto direct_call_solve_LP(
    const pm::Matrix<pm::Rational>& inequalities,
    const pm::Matrix<pm::Rational>& equalities,
    const pm::Vector<pm::Rational>& objective,
    bool                            maximize)
{
    try {
        auto solution = polymake::polytope::solve_LP(inequalities, equalities, objective, maximize);
        return solution.solution;
    } catch (...) {
        return pm::Vector<pm::Rational>();
    }
}

auto direct_call_solve_LP_float(
    const pm::Matrix<double>& inequalities,
    const pm::Matrix<double>& equalities,
    const pm::Vector<double>& objective,
    bool                      maximize)
{
    try {
        auto solution = polymake::polytope::solve_LP(inequalities, equalities, objective, maximize);
        return solution.solution;
    } catch (...) {
        return pm::Vector<double>();
    }
}


void polymake_module_add_direct_calls(jlcxx::Module& polymake)
{
    polymake.method("direct_call_solve_LP", &direct_call_solve_LP);
    polymake.method("direct_call_solve_LP_float", &direct_call_solve_LP_float);
}
