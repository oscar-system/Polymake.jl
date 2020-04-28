#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_type_modules.h"

#include "polymake_caller.h"

#include "generated/option_set_take.h"

void polymake_module_add_bigobject(jlcxx::Module& polymake)
{

    polymake.add_type<pm::perl::PropertyValue>("PropertyValue");
    polymake.add_type<pm::perl::OptionSet>("OptionSet");

    polymake.method("option_set_take", option_set_take);

    polymake.add_type<pm::perl::BigObjectType>("BigObjectType")
        .constructor<const std::string&>()
        .method("type_name", [](pm::perl::BigObjectType p) { return p.name(); });

    polymake.add_type<pm::perl::BigObject>("BigObject")
        .constructor<const pm::perl::BigObjectType&>()
        .constructor<const pm::perl::BigObjectType&, const pm::perl::BigObject&>()
        .method("save_bigobject",
                [](pm::perl::BigObject p, const std::string& s) {
                    return p.save(s);
                })
        .method(
            "load_bigobject",
            [](const std::string& s) { return pm::perl::BigObject::load(s); })
        .method("internal_give",
                [](pm::perl::BigObject p, const std::string& s) {
                    return p.give(s);
                })
        .method("exists", [](pm::perl::BigObject& p,
                             const std::string& s) { return p.exists(s); })
        .method("_isa", [](const pm::perl::BigObject& p,
                          const pm::perl::BigObjectType& t) { return p.isa(t); })
        .method("cast!", [](pm::perl::BigObject& p,
                            const pm::perl::BigObjectType& t) { return p.cast(t); })
        .method("bigobject_type", [](pm::perl::BigObject p) { return p.type(); })
        .method("type_name",
                [](pm::perl::BigObject p) { return p.type().name(); })
        .method("properties", [](pm::perl::BigObject p) {
            std::string x = p.call_method("properties");
            return x;
        });

    polymake.method("to_bool", [](pm::perl::PropertyValue p) {
        return static_cast<bool>(p);
    });
    polymake.method("to_int", [](pm::perl::PropertyValue p) {
        return static_cast<pm::Int>(p);
    });
    polymake.method("to_double", [](pm::perl::PropertyValue p) {
        return static_cast<double>(p);
    });
    polymake.method("to_string", [](pm::perl::PropertyValue p) {
        return to_SmallObject<std::string>(p);
    });
    polymake.method("to_bigobject", &to_bigobject);

    polymake.method("setname!", [](pm::perl::BigObject p, const std::string& s){
        p.set_name(s);
    });
    polymake.method("take", [](pm::perl::BigObject p, const std::string& s,
                               const std::string& t) { p.take(s) << t; });
    polymake.method("take",
                    [](pm::perl::BigObject p, const std::string& s,
                       const pm::perl::PropertyValue& v) { p.take(s) << v; });
    polymake.method("take",
                    [](pm::perl::BigObject p, const std::string& s,
                       const pm::perl::BigObject& v) { p.take(s) << v; });
    polymake.method("add", [](pm::perl::BigObject p, const std::string& s,
                              const pm::perl::BigObject& v) { p.add(s, v); });

    polymake.method("typeinfo_string",
                    [](pm::perl::PropertyValue p, bool demangle) {
                        return typeinfo_helper(p, demangle);
                    });
    polymake.method("check_defined", [](pm::perl::PropertyValue v) {
        return PropertyValueHelper(v).is_defined();
    });
}
