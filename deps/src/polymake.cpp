#include <string>
#include <iostream>

#include "jlcxx/jlcxx.hpp"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wlogical-op-parentheses"
#pragma clang diagnostic ignored "-Wshift-op-parentheses"
#include <polymake/Main.h>
#include <polymake/Matrix.h>
#include <polymake/Vector.h>
#include <polymake/IncidenceMatrix.h>
#include <polymake/Rational.h>

#include <polymake/perl/Value.h>
#include <polymake/perl/calls.h>
#pragma clang diagnostic pop

using namespace polymake;

namespace {

class PropertyValueHelper : public pm::perl::PropertyValue {
   public:
      PropertyValueHelper(const pm::perl::PropertyValue& pv) : pm::perl::PropertyValue(pv) {};

      std::string get_typename() {
         switch (this->classify_number()) {

         // primitives
         case number_is_zero:
         case number_is_int:
            return "int";
         case number_is_float:
            return "double";

         // with typeinfo ptr (nullptr for Objects)
         case number_is_object:
            // some non-primitive Scalar type with typeinfo (e.g. Rational)
         case not_a_number:
            // a c++ type with typeinfo or a perl Object
            {
               const std::type_info* ti = this->get_canned_typeinfo();
               if (ti == nullptr) {
                  // perl object
                  return "perl::Object";
               } else {
                  return legible_typename(*ti);
               }
            }
         default:
            throw std::runtime_error("get_typename: could not determine property type");
         }
      }
};

}


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

// We can do better templating here
template<typename T>
std::string show_small_object(T obj){
    std::ostringstream buffer;
    wrap(buffer) << polymake::legible_typename(typeid(obj)) << pm::endl << obj;
    return buffer.str();
}

std::string (*show_integer)(pm::Integer obj) = &show_small_object<pm::Integer>;
std::string (*show_rational)(pm::Rational obj) = &show_small_object<pm::Rational>;
std::string (*show_vec_integer)(pm::Vector<pm::Integer>  obj) = &show_small_object<pm::Vector<pm::Integer> >;
std::string (*show_vec_rational)(pm::Vector<pm::Rational>  obj) = &show_small_object<pm::Vector<pm::Rational> >;
std::string (*show_mat_integer)(pm::Matrix<pm::Integer>  obj) = &show_small_object<pm::Matrix<pm::Integer> >;
std::string (*show_mat_rational)(pm::Matrix<pm::Rational>  obj) = &show_small_object<pm::Matrix<pm::Rational> >;


JULIA_CPP_MODULE_BEGIN(registry)
  jlcxx::Module& polymake = registry.create_module("Polymake");

  polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");

  polymake.add_type<pm::perl::Object>("pm_perl_Object")
    .constructor<const std::string&>()
    .method("give",[](pm::perl::Object p, const std::string& s){ return p.give(s); })
    .method("exists",[](pm::perl::Object p, const std::string& s){ return p.exists(s); })
    .method("properties",[](pm::perl::Object p){ std::string x = p.call_method("properties"); 
                                                 return x; 
                                                });

  polymake.add_type<pm::Integer>("pm_Integer")
    .constructor<int32_t>()
    .constructor<int64_t>();
  polymake.method("new_pm_Integer",new_integer_from_bigint);

  polymake.add_type<pm::Rational>("pm_Rational")
    .constructor<int32_t, int32_t>()
    .constructor<int64_t, int64_t>()
    .template constructor<pm::Integer, pm::Integer>()
    .method("numerator",[](pm::Rational r){ return pm::Integer(numerator(r)); })
    .method("denominator",[](pm::Rational r){ return pm::Integer(denominator(r)); });

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Matrix")
    .apply<pm::Matrix<pm::Integer>, pm::Matrix<pm::Rational>>([](auto wrapped){
        typedef typename decltype(wrapped)::type WrappedT;
        // typedef typename decltype(wrapped)::foo X;
        wrapped.method([](WrappedT& f, int i, int j){ return typename WrappedT::value_type(f(i,j));});
        wrapped.method("set_entry",[](WrappedT& f, int i, int j, typename WrappedT::value_type r){
            f(i,j)=r;
        });
        wrapped.method("rows",&WrappedT::rows);
        wrapped.method("cols",&WrappedT::cols);
        wrapped.method("resize",[](WrappedT& T, int i, int j){ T.resize(i,j); });
        wrapped.template constructor<int, int>();
        wrapped.method("take",[](pm::perl::Object p, const std::string& s, WrappedT& T){
            p.take(s) << T;
        });
    });

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Vector")
    .apply<pm::Vector<pm::Integer>, pm::Vector<pm::Rational>>([](auto wrapped){
        typedef typename decltype(wrapped)::type WrappedT;
        // typedef typename decltype(wrapped)::foo X;
        wrapped.method([](WrappedT& f, int i){ return typename WrappedT::value_type(f[i]);});
        wrapped.method("set_entry",[](WrappedT& f, int i, typename WrappedT::value_type r){
            f[i]=r;
        });
        wrapped.method("dim",&WrappedT::dim);
        wrapped.method("resize",[](WrappedT& T, int i){ T.resize(i); });
        wrapped.template constructor<int>();
        wrapped.method("take",[](pm::perl::Object p, const std::string& s, WrappedT& T){
            p.take(s) << T;
        });
    });

  polymake.method("init", &initialize_polymake);
  polymake.method("call_func_0args",&call_func_0args);
  polymake.method("call_func_1args",&call_func_1args);
  polymake.method("call_func_2args",&call_func_2args);
  polymake.method("application",[](const std::string x){ data.main_polymake_session->set_application(x); });

  polymake.method("to_int",[](pm::perl::PropertyValue p){ return static_cast<long>(p);});
  polymake.method("to_double",[](pm::perl::PropertyValue p){ return static_cast<double>(p);});
  polymake.method("to_bool",[](pm::perl::PropertyValue p){ return static_cast<bool>(p);});
  polymake.method("to_perl_object",&to_perl_object);
  polymake.method("to_pm_Integer",&to_pm_Integer);
  polymake.method("to_pm_Rational",&to_pm_Rational);
  polymake.method("to_vector_rational",to_vector_rational);
  polymake.method("to_vector_int",to_vector_integer);
  polymake.method("to_matrix_rational",to_matrix_rational);
  polymake.method("to_matrix_int",to_matrix_integer);
  polymake.method("typeinfo_string", [](pm::perl::PropertyValue p){ PropertyValueHelper ph(p); return ph.get_typename(); });

  polymake.method("show_small_obj",show_integer);
  polymake.method("show_small_obj",show_rational);
  polymake.method("show_small_obj",show_vec_integer);
  polymake.method("show_small_obj",show_vec_rational);
  polymake.method("show_small_obj",show_mat_integer);
  polymake.method("show_small_obj",show_mat_rational);


JULIA_CPP_MODULE_END
