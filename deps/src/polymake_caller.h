#ifndef POLYMAKE_WRAP_CALLER
#define POLYMAKE_WRAP_CALLER

#include "polymake_includes.h"

#ifdef INCLUDED_FROM_CALLER
    #define CreatePolymakeTypeVar(type) jl_value_t* POLYMAKETYPE_ ## type
#else
    #define CreatePolymakeTypeVar(type) extern jl_value_t* POLYMAKETYPE_ ## type
#endif

CreatePolymakeTypeVar(pm_perl_PropertyValue);
CreatePolymakeTypeVar(pm_perl_OptionSet);
CreatePolymakeTypeVar(pm_perl_Value);
CreatePolymakeTypeVar(pm_perl_Object);
CreatePolymakeTypeVar(pm_Integer);
CreatePolymakeTypeVar(pm_Rational);
CreatePolymakeTypeVar(pm_Matrix_pm_Integer);
CreatePolymakeTypeVar(pm_Matrix_pm_Rational);
CreatePolymakeTypeVar(pm_Vector_pm_Integer);
CreatePolymakeTypeVar(pm_Vector_pm_Rational);
CreatePolymakeTypeVar(pm_Set_Int64);
CreatePolymakeTypeVar(pm_Set_Int32);

#define POLYMAKE_INSERT_TYPE_IN_MAP(type) insert_type_in_map(#type , &POLYMAKETYPE_ ## type )
#define POLYMAKE_INSERT_TYPE_IN_MAP_SINGLE_TEMPLATE(outer,inner) \
     insert_type_in_map( std::string( #outer ) + "_" + #inner  , &POLYMAKETYPE_ ## outer ## _ ## inner  )

void insert_type_in_map(std::string&&, jl_value_t**);

void set_julia_type(std::string, void*);

void polymake_module_add_caller(jlcxx::Module&);

#endif