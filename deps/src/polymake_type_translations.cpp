#include "polymake_includes.h"

#include "polymake_type_modules.h"

#include "generated/get_type_names.h"

void polymake_module_add_type_translations(jlcxx::Module& polymake)
{
    polymake.method("get_type_names", &get_type_names);
}
