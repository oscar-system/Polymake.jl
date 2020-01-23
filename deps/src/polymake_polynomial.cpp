#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_polynomial.h"

void polymake_module_add_polynomial(jlcxx::Module& polymake)
{
    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>, jlcxx::TypeVar<2>>>(
            "pm_Polynomial", jlcxx::julia_type("Any", "Base"))
        .apply_combination<pm::Polynomial, pm_VecOrMat_supported::value_type, pm_VecOrMat_supported::value_type>(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type polyT;
                typedef typename decltype(wrapped)::type::coefficient_type coeffT;
                typedef typename decltype(wrapped)::type::monomial_type::value_type expT;

                wrapped.template constructor<pm::Vector<coeffT>, pm::Matrix<expT>>();

                wrapped.method("==", [](polyT& a, polyT& b) { return a == b; });
                wrapped.method("+", [](polyT& a, polyT& b) { return a + b; });
                wrapped.method("-", [](polyT& a, polyT& b) { return a - b; });
                wrapped.method("*", [](polyT& a, polyT& b) { return a * b; });
                wrapped.method("^", [](polyT& a, int32_t b) { return a ^ b; });
                // wrapped.method("^", [](polyT& a, pm::Integer b) { return a ^ b; });
                // wrapped.method("^", [](polyT& a, pm::Rational b) { return a ^ b; });
                // wrapped.method("^", [](polyT& a, double b) { return a ^ b; });
                wrapped.method("/", [](polyT& a, coeffT& c) { return a / c; });
                wrapped.method("coefficients_as_vector", &polyT::coefficients_as_vector);
                wrapped.method("monomials_as_matrix", [](polyT& a) { return a.monomials_as_matrix(); });
                wrapped.method("set_var_names", [](polyT& a, Array<std::string>& names) { a.set_var_names(names); });
                // wrapped.method("get_var_names", &polyT::get_var_names);
                wrapped.method("get_var_names", [](polyT& a) { return a.get_var_names(); });

                wrapped.method("show_small_obj", [](polyT& P) {
                    return show_small_object<polyT>(P);
                });
                wrapped.method("take",
                    [](pm::perl::Object p, const std::string& s,
                        polyT& P){ p.take(s) << P; });
        });

    polymake.method("to_pm_polynomial_int_int", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<int,int>>(v);
        });
    polymake.method("to_pm_polynomial_int_Integer", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<int,pm::Integer>>(v);
        });
    polymake.method("to_pm_polynomial_int_Rational", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<int,pm::Rational>>(v);
        });
    polymake.method("to_pm_polynomial_int_double", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<int,double>>(v);
        });
    polymake.method("to_pm_polynomial_Integer_int", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Integer,int>>(v);
        });
    polymake.method("to_pm_polynomial_Integer_Integer", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Integer,pm::Integer>>(v);
        });
    polymake.method("to_pm_polynomial_Integer_Rational", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Integer,pm::Rational>>(v);
        });
    polymake.method("to_pm_polynomial_Integer_double", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Integer,double>>(v);
        });
    polymake.method("to_pm_polynomial_Rational_int", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Rational,int>>(v);
        });
    polymake.method("to_pm_polynomial_Rational_Integer", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Rational,pm::Integer>>(v);
        });
    polymake.method("to_pm_polynomial_Rational_Rational", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Rational,pm::Rational>>(v);
        });
    polymake.method("to_pm_polynomial_Rational_double", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<pm::Rational,double>>(v);
        });
    polymake.method("to_pm_polynomial_double_int", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<double,int>>(v);
        });
    polymake.method("to_pm_polynomial_double_Integer", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<double,pm::Integer>>(v);
        });
    polymake.method("to_pm_polynomial_double_Rational", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<double,pm::Rational>>(v);
        });
    polymake.method("to_pm_polynomial_double_double", [](pm::perl::PropertyValue v) {
            return to_SmallObject<pm::Polynomial<double,double>>(v);
        });
}
