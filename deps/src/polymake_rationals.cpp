#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_integers.h"

#include "polymake_rationals.h"

void polymake_module_add_rational(jlcxx::Module& polymake)
{

    polymake
        .add_type<pm::Rational>("pm_Rational",
                                jlcxx::julia_type("Real", "Base"))
        .constructor<int32_t, int32_t>()
        .constructor<int64_t, int64_t>()
        .constructor<pm::Integer, pm::Integer>()
        .method("==", [](pm::Rational& a, pm::Rational& b) { return a == b; })
        .method("==", [](pm::Rational& a, pm::Integer& b) { return a == b; })
        .method("==", [](pm::Rational& a,
                         int64_t b) { return a == static_cast<long>(b); })
        .method("==", [](pm::Rational& a, int32_t b) { return a == b; })
        .method("==", [](pm::Integer& a, pm::Rational& b) { return a == b; })
        .method("==",
                [](int64_t a, pm::Rational& b) {
                    return static_cast<long>(a) == b;
                })
        .method("==",
                [](int32_t a, pm::Rational& b) {
                    return static_cast<long>(a) == b;
                })

        .method("<", [](pm::Rational& a, pm::Rational& b) { return a < b; })
        .method("<", [](pm::Rational& a, pm::Integer& b) { return a < b; })
        .method("<", [](pm::Rational& a,
                        int64_t       b) { return a < static_cast<long>(b); })
        .method("<", [](pm::Rational& a, int32_t b) { return a < b; })
        .method("<", [](pm::Integer& a, pm::Rational& b) { return a < b; })
        .method("<", [](int64_t       a,
                        pm::Rational& b) { return static_cast<long>(a) < b; })
        .method("<", [](int32_t       a,
                        pm::Rational& b) { return static_cast<long>(a) < b; })

        .method("<=", [](pm::Rational& a, pm::Rational& b) { return a <= b; })
        .method("<=", [](pm::Rational& a, pm::Integer& b) { return a <= b; })
        .method("<=", [](pm::Rational& a,
                         int64_t b) { return a <= static_cast<long>(b); })
        .method("<=", [](pm::Rational& a, int32_t b) { return a <= b; })
        .method("<=", [](pm::Integer& a, pm::Rational& b) { return a <= b; })
        .method("<=",
                [](int64_t a, pm::Rational& b) {
                    return static_cast<long>(a) <= b;
                })
        .method("<=", [](int32_t a, pm::Rational& b) { return a <= b; })

        .method(
            "numerator",
            [](const pm::Rational& r) { return pm::Integer(numerator(r)); })
        .method(
            "denominator",
            [](const pm::Rational& r) { return pm::Integer(denominator(r)); })
        .method("show_small_obj",
                [](const pm::Rational& r) {
                    return show_small_object<pm::Rational>(r, false);
                })
        // the symmetric definitions are on the julia side
        .method("+", [](pm::Rational& a, pm::Rational& b) { return a + b; })
        .method("+", [](pm::Rational& a, pm::Integer& b) { return a + b; })
        .method("+", [](pm::Rational& a,
                        int64_t       b) { return a + static_cast<long>(b); })
        .method("+", [](pm::Rational& a, int32_t b) { return a + b; })
        .method("+", [](pm::Integer& a, pm::Rational& b) { return a + b; })
        .method("+", [](int64_t       a,
                        pm::Rational& b) { return static_cast<long>(a) + b; })
        .method("+", [](int32_t a, pm::Rational& b) { return a + b; })

        .method("*", [](pm::Rational& a, pm::Rational& b) { return a * b; })
        .method("*", [](pm::Rational& a, pm::Integer& b) { return a * b; })
        .method("*", [](pm::Rational& a,
                        int64_t       b) { return a * static_cast<long>(b); })
        .method("*", [](pm::Rational& a, int32_t b) { return a * b; })
        .method("*", [](pm::Integer& a, pm::Rational& b) { return a * b; })
        .method("*", [](int64_t       a,
                        pm::Rational& b) { return static_cast<long>(a) * b; })
        .method("*", [](int32_t a, pm::Rational& b) { return a * b; })

        .method("-", [](pm::Rational& a, pm::Rational& b) { return a - b; })
        .method("-", [](pm::Rational& a, pm::Integer& b) { return a - b; })
        .method("-", [](pm::Rational& a,
                        int64_t       b) { return a - static_cast<long>(b); })
        .method("-", [](pm::Rational& a, int32_t b) { return a - b; })
        .method("-", [](pm::Integer& a, pm::Rational& b) { return a - b; })
        .method("-", [](int64_t       a,
                        pm::Rational& b) { return static_cast<long>(a) - b; })
        .method("-", [](int32_t a, pm::Rational& b) { return a - b; })
        // unary minus
        .method("-", [](pm::Rational& a) { return -a; })

        .method("/", [](pm::Rational& a, pm::Rational& b) { return a / b; })
        .method("/", [](pm::Rational& a, pm::Integer& b) { return a / b; })
        .method("/", [](pm::Rational& a,
                        int64_t       b) { return a / static_cast<long>(b); })
        .method("/", [](pm::Rational& a, int32_t b) { return a / b; })
        .method("/", [](pm::Integer& a, pm::Rational& b) { return a / b; })
        .method("/", [](int64_t       a,
                        pm::Rational& b) { return static_cast<long>(a) / b; })
        .method("/", [](int32_t a, pm::Rational& b) { return a / b; });

    polymake.method("to_pm_Rational", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Rational>(pv);
    });
}
