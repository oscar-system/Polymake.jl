#include "polymake_includes.h"

#include "polymake_type_translations.h"

#include "generated/real_type_names.h"

#include <cxxabi.h>
#include <typeinfo>

#define TYPE_TRANSLATOR(type, translate_func)                                \
    type_name_tuples[i] = jl_cstr_to_string(#translate_func);                \
    realname = abi::__cxa_demangle(typeid(type).name(), 0, 0, &status);      \
    type_name_tuples[i + 1] = jl_cstr_to_string(realname);                   \
    free(realname);                                                          \
    i += 2;


jlcxx::ArrayRef<jl_value_t*> get_type_names()
{
    int          status;
    char*        realname;
    int          number_of_types = NUMBER_OF_TYPES;
    jl_value_t** type_name_tuples = new jl_value_t*[2 * number_of_types];
    int          i = 0;
    TYPE_TRANSLATIONS
    return jlcxx::make_julia_array(type_name_tuples, 2 * number_of_types);
}

void polymake_module_add_type_translations(jlcxx::Module& polymake)
{
    polymake.method("get_type_names", &get_type_names);
}