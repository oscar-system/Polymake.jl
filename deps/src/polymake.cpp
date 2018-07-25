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

polymake::perl::Object cube(int dim) {
    return polymake::call_function("cube",dim);
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

JULIA_CPP_MODULE_BEGIN(registry)
  jlcxx::Module& polymake = registry.create_module("Polymake");
  polymake.add_type<pm::perl::Object>("PolymakeObject");
  polymake.add_type<pm::perl::PropertyValue>("PolymakeValue");
  polymake.method("init", &initialize_polymake);
  polymake.method("cube",&cube);
  polymake.method("application",&application);
  polymake.method("give",&give);
  polymake.method("exists",&exists);
  polymake.method("properties",&properties);
  polymake.method("to_int",&to_int);
JULIA_CPP_MODULE_END

// std::string greet()
// {
//    return "hello, world";
// }

// JULIA_CPP_MODULE_BEGIN(registry)
//   jlcxx::Module& hello = registry.create_module("Polymake");
//   hello.method("greet", &greet);
// JULIA_CPP_MODULE_END