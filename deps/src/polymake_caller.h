#ifndef POLYMAKE_WRAP_CALLER
#define POLYMAKE_WRAP_CALLER

#include "polymake_includes.h"

#include "generated/type_declarations_extern.h"

void insert_type_in_map(std::string&&, jl_value_t**);

void set_julia_type(std::string, void*);

void polymake_module_add_caller(jlcxx::Module&);

#endif
