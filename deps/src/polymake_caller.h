#ifndef POLYMAKE_WRAP_CALLER
#define POLYMAKE_WRAP_CALLER

#include "polymake_includes.h"

#ifdef INCLUDED_FROM_CALLER
#define CreatePolymakeTypeVar(type) jl_value_t* POLYMAKETYPE_##type
#else
#define CreatePolymakeTypeVar(type) extern jl_value_t* POLYMAKETYPE_##type
#endif

#include "generated/type_vars.h"

#define POLYMAKE_INSERT_TYPE_IN_MAP(type)                                    \
    insert_type_in_map(#type, &POLYMAKETYPE_##type)
#define POLYMAKE_INSERT_TYPE_IN_MAP_SINGLE_TEMPLATE(outer, inner)            \
    insert_type_in_map(std::string(#outer) + "_" + #inner,                   \
                       &POLYMAKETYPE_##outer##_##inner)

void insert_type_in_map(std::string&&, jl_value_t**);

void set_julia_type(std::string, void*);

void polymake_module_add_caller(jlcxx::Module&);

#endif
