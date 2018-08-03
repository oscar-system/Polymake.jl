#include <string>
#include <iostream>

#include "jlcxx/jlcxx.hpp"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wlogical-op-parentheses"
#pragma clang diagnostic ignored "-Wshift-op-parentheses"
#include <polymake/Main.h>
#include <polymake/Matrix.h>
#include <polymake/IncidenceMatrix.h>
#include <polymake/Rational.h>
#pragma clang diagnostic pop


struct Polymake_Data {
   polymake::Main *main_polymake_session;
   polymake::perl::Scope *main_polymake_scope;
};

static Polymake_Data data;

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

void application(std::string x){
   data.main_polymake_session->set_application(x);
}

auto give(pm::perl::Object p, std::string prop){
    return p.give(prop);
}

bool exists(pm::perl::Object p, std::string prop){
    return p.exists(prop);
}

std::string properties (pm::perl::Object p){
    return p.call_method("properties");
}

int to_int(pm::perl::PropertyValue v){
    return static_cast<int>(v);
}

pm::Integer to_bigint(pm::perl::PropertyValue v){
    pm::Integer integer = v;
    return integer;
}

pm::Rational to_rational(pm::perl::PropertyValue v){
    pm::Rational integer = v;
    return integer;
}

bool to_bool(pm::perl::PropertyValue v){
    return static_cast<bool>(v);
}

pm::Rational abs_func(pm::Rational r){
    return abs(r);
}

pm::Integer get_numerator(pm::Rational r){
    return numerator(r);
}

pm::Integer get_denominator(pm::Rational r){
    return denominator(r);
}

pm::Matrix<pm::Rational> to_matrix_rational(pm::perl::PropertyValue v){
    pm::Matrix<pm::Rational> m = v;
    return m;
}

pm::Matrix<pm::Integer> to_matrix_int(pm::perl::PropertyValue v){
    pm::Matrix<pm::Integer> m = v;
    return m;
}

int get_matrix_columns( pm::Matrix<pm::Rational> m){
    return m.cols();
}

int get_matrix_rows( pm::Matrix<pm::Rational> m){
    return m.rows();
}

pm::Rational get_matrix_entry_rational(pm::Matrix<pm::Rational> m, int i, int j){
    return m(i,j);
}

pm::Integer get_matrix_entry_int(pm::Matrix<pm::Integer> m, int i, int j){
    return m(i,j);
}

JULIA_CPP_MODULE_BEGIN(registry)
  jlcxx::Module& polymake = registry.create_module("Polymake");
  polymake.add_type<pm::perl::Object>("pm_perl_Object");
  polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");
  polymake.add_type<pm::Integer>("pm_Integer")
    .constructor<int>()
    .constructor<long>();
  polymake.add_type<pm::Rational>("pm_Rational")
    .constructor<int, int>()
    .constructor<long, long>();
  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Matrix")
    .apply<pm::Matrix<pm::Integer>, pm::Matrix<pm::Rational>>([](auto wrapped){
        typedef typename decltype(wrapped)::type WrappedT;
        // typedef typename decltype(wrapped)::foo X;
        wrapped.method([](WrappedT f, int i, int j){ return f(i,j);});
        wrapped.method("set_entry",[](WrappedT f, int i, int j, typename WrappedT::value_type r){
            f(i,j)=r;
        });
        wrapped.method("rows",&WrappedT::rows);
        wrapped.method("cols",&WrappedT::cols);
        wrapped.method("resize",[](WrappedT& T, int i, int j){ T.resize(i,j); });
        wrapped.template constructor<int, int>();
    });
//   polymake.add_type<pm::Matrix<pm::Rational> >("pm_Matrix_pm_Rational");
//   polymake.add_type<pm::Matrix<pm::Integer> >("pm_Matrix_pm_Integer");

  polymake.method("init", &initialize_polymake);
  polymake.method("call_func_0args",&call_func_0args);
  polymake.method("call_func_1args",&call_func_1args);
  polymake.method("call_func_2args",&call_func_2args);
  polymake.method("application",&application);
  polymake.method("give",&give);
  polymake.method("exists",&exists);
  polymake.method("properties",&properties);

  polymake.method("to_int",&to_int);
  polymake.method("to_bigint",&to_bigint);
  polymake.method("to_rational",&to_rational);
  polymake.method("to_bool",&to_bool);
  polymake.method("to_matrix_rational",&to_matrix_rational);
  polymake.method("to_matrix_int",&to_matrix_int);

  polymake.method("numerator",&get_numerator);
  polymake.method("denominator",&get_denominator);
  polymake.method("get_matrix_columns",&get_matrix_columns);
  polymake.method("get_matrix_rows",&get_matrix_rows);
  polymake.method("get_matrix_entry_rational",&get_matrix_entry_rational);
  polymake.method("get_matrix_entry_int",&get_matrix_entry_int);
JULIA_CPP_MODULE_END

// std::string greet()
// {
//    return "hello, world";
// }

// JULIA_CPP_MODULE_BEGIN(registry)
//   jlcxx::Module& hello = registry.create_module("Polymake");
//   hello.method("greet", &greet);
// JULIA_CPP_MODULE_END