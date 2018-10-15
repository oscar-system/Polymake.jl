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

pm::Integer to_pm_Integer(pm::perl::PropertyValue v){
    pm::Integer integer = v;
    return integer;
}

pm::Rational to_pm_Rational(pm::perl::PropertyValue v){
    pm::Rational integer = v;
    return integer;
}

bool to_bool(pm::perl::PropertyValue v){
    return static_cast<bool>(v);
}

template<typename T>
pm::Vector<T> to_vector_T(pm::perl::PropertyValue v){
    pm::Vector<T> m = v;
    return m;
}
pm::Vector<pm::Integer> (*to_vector_integer)(pm::perl::PropertyValue) = &to_vector_T<pm::Integer>;
pm::Vector<pm::Rational> (*to_vector_rational)(pm::perl::PropertyValue) = &to_vector_T<pm::Rational>;

template<typename T>
pm::Matrix<T> to_matrix_T(pm::perl::PropertyValue v){
    pm::Matrix<T> m = v;
    return m;
}
pm::Matrix<pm::Integer> (*to_matrix_integer)(pm::perl::PropertyValue) = &to_matrix_T<pm::Integer>;
pm::Matrix<pm::Rational> (*to_matrix_rational)(pm::perl::PropertyValue) = &to_matrix_T<pm::Rational>;

pm::Integer new_integer_from_bigint(jl_value_t* integer){
    pm::Integer* p;
    p = reinterpret_cast<pm::Integer*>(integer);
    return *p;
}

std::string (*show_integer)(const pm::Integer& obj) = &show_small_object<pm::Integer>;
std::string (*show_rational)(const pm::Rational& obj) = &show_small_object<pm::Rational>;
std::string (*show_vec_integer)(const pm::Vector<pm::Integer>&  obj) = &show_small_object<pm::Vector<pm::Integer> >;
std::string (*show_vec_rational)(const pm::Vector<pm::Rational>&  obj) = &show_small_object<pm::Vector<pm::Rational> >;
std::string (*show_mat_integer)(const pm::Matrix<pm::Integer>&  obj) = &show_small_object<pm::Matrix<pm::Integer> >;
std::string (*show_mat_rational)(const pm::Matrix<pm::Rational>&  obj) = &show_small_object<pm::Matrix<pm::Rational> >;
