#define INCLUDED_FROM_CALLER

#include "polymake_caller.h"

#include "polymake_tools.h"

#include <vector>

static auto type_map_translator = new std::map<std::string, jl_value_t**>();

void insert_type_in_map(std::string&& ptr_name, jl_value_t** var_space)
{
    type_map_translator->emplace(std::make_pair(ptr_name, var_space));
}

void set_julia_type(std::string name, void* type_address)
{
    jl_value_t** address;
    try {
        address = (*type_map_translator)[name];
    }
    catch (std::exception& e) {
        std::cerr << "This should never happen: " << name << std::endl;
        return;
    }
    memcpy(address, &type_address, sizeof(jl_value_t*));
}


#define TO_POLYMAKE_FUNCTION(juliatype, ctype)                               \
    if (jl_subtype(current_type, POLYMAKETYPE_##juliatype)) {                \
        function << *reinterpret_cast<ctype*>(                               \
            get_ptr_from_cxxwrap_obj(argument));                             \
        return;                                                              \
    }

template <typename T>
void polymake_call_function_feed_argument(T& function, jl_value_t* argument)
{
    jl_value_t* current_type = jl_typeof(argument);
    if (jl_is_int64(argument)) {
        // check size of long, to be sure
        static_assert(sizeof(long) == 8, "long must be 64 bit");
        function << static_cast<long>(jl_unbox_int64(argument));
        return;
    }
    if (jl_is_bool(argument)) {
        function << jl_unbox_bool(argument);
        return;
    }
    if (jl_is_string(argument)) {
        function << std::string(jl_string_data(argument));
        return;
    }
#include "generated/to_polymake_function.h"
}

std::vector<std::string>
create_template_vector(jlcxx::ArrayRef<std::string> template_parameters)
{
    size_t                   number_templates = template_parameters.size();
    std::vector<std::string> return_vector(number_templates);
    for (size_t i = 0; i < number_templates; i++) {
        return_vector[i] = template_parameters[i];
    }
    return return_vector;
}

pm::perl::PropertyValue
polymake_call_function(std::string                  function_name,
                       jlcxx::ArrayRef<std::string> template_parameters,
                       jlcxx::ArrayRef<jl_value_t*> arguments)
{
    std::vector<std::string> template_vector =
        create_template_vector(template_parameters);
    size_t argument_list = arguments.size();
    auto   function = polymake::prepare_call_function(function_name, template_vector);
    for (size_t i = 0; i < argument_list; i++) {
        polymake_call_function_feed_argument(function, arguments[i]);
    }
    return function();
}

// Visualization in polymake only works if the function is called and
// then immediately released,i.e. not converted to a property value
void polymake_call_function_void(
    std::string                  function_name,
    jlcxx::ArrayRef<std::string> template_parameters,
    jlcxx::ArrayRef<jl_value_t*> arguments)
{
    std::vector<std::string> template_vector =
        create_template_vector(template_parameters);
    size_t argument_list = arguments.size();
    auto   function = polymake::prepare_call_function(function_name, template_vector);
    for (size_t i = 0; i < argument_list; i++) {
        polymake_call_function_feed_argument(function, arguments[i]);
    }
    function();
}

pm::perl::PropertyValue
polymake_call_method(std::string                  function_name,
                     pm::perl::Object*            object,
                     jlcxx::ArrayRef<jl_value_t*> arguments)
{
    size_t argument_list = arguments.size();
    auto   function = object->prepare_call_method(function_name);
    for (size_t i = 0; i < argument_list; i++) {
        polymake_call_function_feed_argument(function, arguments[i]);
    }
    return function();
}

// Visualization in polymake only works if the method is called and
// then immediately released,i.e. not converted to a property value
void polymake_call_method_void(std::string                  function_name,
                               pm::perl::Object             object,
                               jlcxx::ArrayRef<jl_value_t*> arguments)
{
    size_t argument_list = arguments.size();
    auto   function = object.prepare_call_method(function_name);
    for (size_t i = 0; i < argument_list; i++) {
        polymake_call_function_feed_argument(function, arguments[i]);
    }
    function();
}


void polymake_module_add_caller(jlcxx::Module& polymake)
{
    polymake.method("internal_call_function", &polymake_call_function);
    polymake.method("internal_call_function_void",
                    &polymake_call_function_void);
    polymake.method("internal_call_method", &polymake_call_method);
    polymake.method("internal_call_method_void", &polymake_call_method_void);
    polymake.method("set_julia_type", &set_julia_type);
}
