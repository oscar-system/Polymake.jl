#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_tropicalnumber.h"

void polymake_module_add_tropicalnumber(jlcxx::Module& polymake)
{
    polymake.add_type<pm::Max>("pm_Max");
    polymake.add_type<pm::Min>("pm_Min");
    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>, jlcxx::TypeVar<2>>>(
            "pm_TropicalNumber", jlcxx::julia_type("Number", "Base"))
            .apply_combination<pm::TropicalNumber,
            jlcxx::ParameterList<pm::Min,pm::Max>,
                jlcxx::ParameterList<pm::Rational>>(
                [](auto wrapped) {
                    typedef typename decltype(wrapped)::type tropType;
                    wrapped.template constructor<pm::Rational>();
                    wrapped.method("+", [](tropType& a, tropType& b) { return a + b; });
                    wrapped.method("*", [](tropType& a, tropType& b) { return a * b; });
                    wrapped.method("//", [](tropType& a, tropType& b) { return a / b; });
                    wrapped.method("==", [](tropType& a,
                            tropType& b) { return a == b; });
                    wrapped.method("<", [](tropType& a,
                            tropType& b) { return a < b; });
                    wrapped.method("scalar", [](tropType&a) { return a.scalar; });
                    wrapped.method("show_small_obj", [](tropType& S) {
                        return show_small_object<tropType>(S);
                    });
            });
    polymake.method("to_pm_tropicalnumber_max_Rational",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::TropicalNumber<pm::Max,pm::Rational>>(pv);
        });
    polymake.method("to_pm_tropicalnumber_min_Rational",
        [](pm::perl::PropertyValue pv) {
            return to_SmallObject<pm::TropicalNumber<pm::Min,pm::Rational>>(pv);
    });
    // polymake.method("to_pm_tropicalnumber_max_Integer",
    //     [](pm::perl::PropertyValue pv) {
    //         return to_SmallObject<pm::TropicalNumber<pm::Max,pm::Integer>>(pv);
    //     });
    // polymake.method("to_pm_tropicalnumber_min_Integer",
    //     [](pm::perl::PropertyValue pv) {
    //         return to_SmallObject<pm::TropicalNumber<pm::Min,pm::Integer>>(pv);
    //     });
}
