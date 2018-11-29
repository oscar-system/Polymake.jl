#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_perl_objects.h"

#include "polymake_caller.h"

#define TO_POLYMAKE_FUNCTION(juliatype, ctype)                               \
    if (jl_subtype(current_type, POLYMAKETYPE_##juliatype)) {                \
        optset[key] << *reinterpret_cast<ctype*>(                            \
            get_ptr_from_cxxwrap_obj(value));                                \
        return;                                                              \
    }

void option_set_take(pm::perl::OptionSet optset,
                     std::string         key,
                     jl_value_t*         value)
{
    jl_value_t* current_type = jl_typeof(value);
    if (jl_is_int64(value)) {
        // check size of long, to be sure
        static_assert(sizeof(long) == 8, "long must be 64 bit");
        optset[key] << static_cast<long>(jl_unbox_int64(value));
        return;
    }
    if (jl_is_bool(value)) {
        optset[key] << jl_unbox_bool(value);
        return;
    }
    if (jl_is_string(value)) {
        optset[key] << std::string(jl_string_data(value));
        return;
    }
#include "generated/to_polymake_function.h"
}

void polymake_module_add_perl_object(jlcxx::Module& polymake)
{

    polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");
    polymake.add_type<pm::perl::OptionSet>("pm_perl_OptionSet");

    polymake.method("option_set_take", option_set_take);


    polymake.add_type<pm::perl::Object>("pm_perl_Object")
        .constructor<const std::string&>()
        .method("save_perl_object",
                [](pm::perl::Object p, const std::string& s) {
                    return p.save(s);
                })
        .method(
            "load_perl_object",
            [](const std::string& s) { return pm::perl::Object::load(s); })
        .method("internal_give",
                [](pm::perl::Object p, const std::string& s) {
                    return p.give(s);
                })
        .method("exists", [](pm::perl::Object   p,
                             const std::string& s) { return p.exists(s); })
        .method("properties", [](pm::perl::Object p) {
            std::string x = p.call_method("properties");
            return x;
        });

    polymake.method("to_bool", [](pm::perl::PropertyValue p) {
        return static_cast<bool>(p);
    });
    polymake.method("to_int", [](pm::perl::PropertyValue p) {
        return static_cast<int64_t>(p);
    });
    polymake.method("to_double", [](pm::perl::PropertyValue p) {
        return static_cast<double>(p);
    });
    polymake.method("to_perl_object", &to_perl_object);

    polymake.method("typeinfo_string", [](pm::perl::PropertyValue p) {
        PropertyValueHelper ph(p);
        return ph.get_typename();
    });

    polymake.method("take", [](pm::perl::Object p, const std::string& s,
                               const std::string& t) { p.take(s) << t; });
    polymake.method("take",
                    [](pm::perl::Object p, const std::string& s,
                       const pm::perl::PropertyValue& v) { p.take(s) << v; });
}
