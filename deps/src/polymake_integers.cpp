#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_type_modules.h"

pm::Integer new_integer_from_bigint(jl_value_t* integer)
{
    pm::Integer* p;
    p = reinterpret_cast<pm::Integer*>(integer);
    return *p;
}

void polymake_module_add_integer(jlcxx::Module& polymake)
{
    polymake
        .add_type<pm::Integer>("Integer",
                               jlcxx::julia_type("Integer", "Base"))
        .constructor<int64_t>()
        .method("<", [](pm::Integer& a, pm::Integer& b) { return a < b; })
        .method("<", [](pm::Integer& a,
                        int64_t      b) { return a < static_cast<pm::Int>(b); })
        .method("<", [](int64_t      a,
                        pm::Integer& b) { return static_cast<pm::Int>(a) < b; })
        .method("<=", [](pm::Integer& a, pm::Integer& b) { return a <= b; })
        .method("<=", [](pm::Integer& a,
                         int64_t b) { return a <= static_cast<pm::Int>(b); })
        .method("<=",
                [](int64_t a, pm::Integer& b) {
                    return static_cast<pm::Int>(a) <= b;
                })

        .method("show_small_obj",
                [](pm::Integer& i) {
                    return show_small_object<pm::Integer>(i, false);
                })
        .method("Float64", [](pm::Integer& a) { return double(a); })
        .method("-", [](pm::Integer& a, pm::Integer& b) { return a - b; })
        .method("-", [](pm::Integer& a,
                        int64_t      b) { return a - static_cast<pm::Int>(b); })
        .method("-", [](int64_t      a,
                        pm::Integer& b) { return static_cast<pm::Int>(a) - b; })
        // unary minus
        .method("-", [](pm::Integer& a) { return -a; })

        .method("div", [](pm::Integer& a, pm::Integer& b) { return a / b; })
        .method("div", [](pm::Integer& a,
                          int64_t b) { return a / static_cast<pm::Int>(b); })
        .method("div",
                [](int64_t a, pm::Integer& b) {
                    return static_cast<pm::Int>(a) / b;
                })

        .method("rem", [](pm::Integer& a, pm::Integer& b) { return a % b; })
        .method("rem", [](pm::Integer& a,
                          int64_t b) { return a % static_cast<pm::Int>(b); })
        .method("rem",
                [](int64_t a, pm::Integer& b) {
                    return static_cast<pm::Int>(a) % b;
                });

        polymake.set_override_module(polymake.julia_module());
        polymake.method("==", [](pm::Integer& a, pm::Integer& b) {
            return a == b; });
        polymake.method("==", [](pm::Integer& a, int64_t b) {
            return a == static_cast<pm::Int>(b); });
        polymake.method("==", [](int64_t a, pm::Integer& b) {
            return static_cast<pm::Int>(a) == b; });

        // the symmetric definitions are on the julia side
        polymake.method("+", [](pm::Integer& a, pm::Integer& b) {
            return a + b; });
        polymake.method("+", [](pm::Integer& a, int64_t b) {
            return a + static_cast<pm::Int>(b); });
        polymake.method("+", [](int64_t a, pm::Integer& b) {
            return static_cast<pm::Int>(a) + b; });
        polymake.method("*", [](pm::Integer& a, pm::Integer& b) {
            return a * b; });
        polymake.method("*", [](pm::Integer& a, int64_t b) {
            return a * static_cast<pm::Int>(b); });
        polymake.method("*", [](int64_t a, pm::Integer& b) {
            return static_cast<pm::Int>(a) * b; });
        polymake.unset_override_module();

    polymake.method("new_integer_from_bigint", new_integer_from_bigint);
    polymake.method("to_integer", [](pm::perl::PropertyValue pv) {
        return to_SmallObject<pm::Integer>(pv);
    });
}
