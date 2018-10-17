#include "polymake_includes.h"
#include "polymake_tools.h"
#include "polymake_caller.h"
#include "polymake_functions.h"

void initialize_polymake(){
    data.main_polymake_session = new polymake::Main;
    data.main_polymake_scope = new polymake::perl::Scope(data.main_polymake_session->newScope());
    std::cout << data.main_polymake_session->greeting() << std::endl;
}

polymake::perl::Object call_func_0args(std::string func) {
    return polymake::call_function(func);
}

polymake::perl::Object call_func_1args(std::string func, int arg1) {
    return polymake::call_function(func, arg1);
}

polymake::perl::Object call_func_2args(std::string func, int arg1, int arg2) {
    return polymake::call_function(func, arg1, arg2);
}

pm::perl::Object to_perl_object(pm::perl::PropertyValue v){
    pm::perl::Object obj;
    v >> obj;
    return v;
}

bool to_bool(pm::perl::PropertyValue v){
    return static_cast<bool>(v);
}

pm::Integer to_pm_Integer(pm::perl::PropertyValue v){
    pm::Integer integer = v;
    return integer;
}

pm::Rational to_pm_Rational(pm::perl::PropertyValue v){
    pm::Rational integer = v;
    return integer;
}

pm::Vector<pm::Integer> (*to_vector_integer)(pm::perl::PropertyValue) = &to_SmallObject<pm::Vector<pm::Integer>>;
pm::Vector<pm::Rational> (*to_vector_rational)(pm::perl::PropertyValue) = &to_SmallObject<pm::Vector<pm::Rational>>;

pm::Matrix<pm::Integer> (*to_matrix_integer)(pm::perl::PropertyValue) = &to_SmallObject<pm::Matrix<pm::Integer>>;
pm::Matrix<pm::Rational> (*to_matrix_rational)(pm::perl::PropertyValue) = &to_SmallObject<pm::Matrix<pm::Rational>>;

pm::Integer new_integer_from_bigint(jl_value_t* integer){
    pm::Integer* p;
    p = reinterpret_cast<pm::Integer*>(integer);
    return *p;
}
