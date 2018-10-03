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
#include <polymake/QuadraticExtension.h>

#include <polymake/perl/Value.h>
#include <polymake/perl/calls.h>

#include <polymake/perl/macros.h>
#include <polymake/perl/wrappers.h>

// #include "/home/sebastian/Software/polymake_devel_git/apps/polytope/include/cube.h"

#pragma clang diagnostic pop

namespace pm{
   template <typename PointedT, typename CppT>
   struct iterator_cross_const_helper<jlcxx::array_iterator_base<PointedT, CppT>,true>{
      typedef jlcxx::array_iterator_base<std::remove_const_t<PointedT>, std::remove_const_t<CppT>> iterator;
      typedef jlcxx::array_iterator_base<std::add_const_t<PointedT>, std::add_const_t<CppT>> const_iterator;
   };
}

using namespace polymake;

namespace {

class PropertyValueHelper : public pm::perl::PropertyValue {
   public:
      PropertyValueHelper(const pm::perl::PropertyValue& pv) : pm::perl::PropertyValue(pv) {};

      bool check_defined() const noexcept{
         return this->is_defined();
      }
      std::string get_typename() {
         if(!this->is_defined()){
             return "undefined";
         }
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

template<typename T>
pm::Set<T> set_T(jlcxx::ArrayRef<T> arr){
   pm::Set<T> s(arr.begin(), arr.end());
   return s;
}
pm::Set<int64_t> (*new_set_int64)(jlcxx::ArrayRef<int64_t> arr) = &set_T<int64_t>;
pm::Set<int32_t> (*new_set_int32)(jlcxx::ArrayRef<int32_t> arr) = &set_T<int32_t>;

template<typename T>
pm::Set<T> to_set_T(pm::perl::PropertyValue v){
   pm::Set<T> s = v;
   return s;
}

pm::Set<int64_t> (*to_set_int64)(pm::perl::PropertyValue) = &to_set_T<int64_t>;
pm::Set<int32_t> (*to_set_int32)(pm::perl::PropertyValue) = &to_set_T<int32_t>;

template<typename T, typename S>
void fill_jlarray_T_from_S(jlcxx::ArrayRef<T> arr, S itr){
   int64_t index{0};
   for(auto i = pm::entire(itr); !i.at_end(); ++i){
      arr[index++] = static_cast<T>(*i);
   }
}

void (*fill_jlarray_int32_from_set32)(jlcxx::ArrayRef<int32_t>, pm::Set<int32_t>) = &fill_jlarray_T_from_S<int32_t, pm::Set<int32_t>>;
void (*fill_jlarray_int64_from_set64)(jlcxx::ArrayRef<int64_t>, pm::Set<int64_t>) = &fill_jlarray_T_from_S<int64_t, pm::Set<int64_t>>;

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
std::string (*show_set_int64)(pm::Set<int64_t>  obj) = &show_small_object<pm::Set<int64_t> >;
std::string (*show_set_int32)(pm::Set<int32_t>  obj) = &show_small_object<pm::Set<int32_t> >;

template<typename T>
pm::perl::Value to_value(T obj){
    pm::perl::Value val;
    val << obj;
    return val;
}

template<typename T>
struct WrappedSetIterator
{
  typename pm::Set<T>::const_iterator iterator;
  using value_type = T;
  WrappedSetIterator<T>(pm::Set<T>& S){
    iterator=pm::entire(S);
  }
};


JLCXX_MODULE define_module_polymake(jlcxx::Module& polymake)
{
  polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");
  polymake.add_type<pm::perl::OptionSet>("pm_perl_OptionSet");
  polymake.add_type<pm::perl::Value>("pm_perl_Value");
  polymake.add_type<pm::operations::cmp>("pm_operations_cmp");

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

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Set")
    .apply<pm::Set<int32_t>, pm::Set<int64_t>>([](auto wrapped){
        typedef typename decltype(wrapped)::type Set;
        wrapped.template constructor<pm::Set<int32_t>>();
        wrapped.template constructor<pm::Set<int64_t>>();
        wrapped.method("swap", &Set::swap);

        wrapped.method("isempty", &Set::empty);
        wrapped.method("length", &Set::size);

        wrapped.method("empty!", [](Set&S){S.clear(); return S;});
        wrapped.method("==", [](Set&S, Set&T){return S == T;});
        wrapped.method("in", [](int64_t i, Set&S){return S.contains(i);});
        wrapped.method("in", [](int32_t i, Set&S){return S.contains(i);});

        wrapped.method("push!", [](Set&S, int64_t i){S+=i; return S;});
        wrapped.method("push!", [](Set&S, int32_t i){S+=i; return S;});

        wrapped.method("delete!", [](Set&S, int64_t i){S-=i; return S;});
        wrapped.method("delete!", [](Set&S, int32_t i){S-=i; return S;});

        wrapped.method("union!", [](Set&S, Set&T){return S += T;});
        wrapped.method("intersect!", [](Set&S, Set&T){return S *= T;});
        wrapped.method("setdiff!", [](Set&S, Set&T){return S -= T;});
        wrapped.method("symdiff!", [](Set&S, Set&T){return S ^= T;});

        wrapped.method("union", [](Set&S, Set&T){return Set{S+T};});
        wrapped.method("intersect", [](Set&S, Set&T){return Set{S*T};});
        wrapped.method("setdiff", [](Set&S, Set&T){return Set{S-T};});
        wrapped.method("symdiff", [](Set&S, Set&T){return Set{S^T};});

        wrapped.method("getindex", [](Set&S, Set&T){
          return Set{pm::select(pm::wary(S), T)};
        });
    });

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("SetIterator")
    .apply<
      WrappedSetIterator<int32_t>,
      WrappedSetIterator<int64_t>
    >([](auto wrapped){
      typedef typename decltype(wrapped)::type WrappedSetIter;
      typedef typename decltype(wrapped)::type::value_type elemType;
      wrapped.method("begin", [](pm::Set<elemType>& S){
        auto result = WrappedSetIterator<elemType>{S};
        return result;
      });
      wrapped.method("get_element", [](WrappedSetIter& state){
        auto elt = *(state.iterator);
        state.iterator++;
        return elt;
      });
      wrapped.method("isdone", [](pm::Set<elemType>& S, WrappedSetIter& state){
        return S.end() == state.iterator;
      });
    });

  polymake.method("incl",
    [](pm::Set<int32_t> s1, pm::Set<int32_t> s2){ return pm::incl(s1,s2);});
  polymake.method("incl",
    [](pm::Set<int32_t> s1, pm::Set<int64_t> s2){ return pm::incl(s1,s2);});
  polymake.method("incl",
    [](pm::Set<int64_t> s1, pm::Set<int32_t> s2){ return pm::incl(s1,s2);});
  polymake.method("incl",
    [](pm::Set<int64_t> s1, pm::Set<int64_t> s2){ return pm::incl(s1,s2);});

  polymake.method("range", [](int32_t a, int32_t b){
     return pm::Set<int32_t>{pm::range(a,b)};
  });
  polymake.method("range", [](int64_t a, int64_t b){
     return pm::Set<int64_t>{pm::range(a,b)};
  });

  polymake.method("sequence",
    [](int32_t a, int32_t c){ return pm::Set<int32_t>{pm::sequence(a,c)};});
  polymake.method("sequence",
    [](int64_t a, int64_t c){ return pm::Set<int64_t>{pm::sequence(a,c)};});

  polymake.method("scalar2set", [](int32_t s){
    return pm::Set<int32_t>{pm::scalar2set(s)};
  });
  polymake.method("scalar2set", [](int64_t s){
    return pm::Set<int32_t>{pm::scalar2set(s)};
  });

  polymake.method("new_set_int64", new_set_int64);
  polymake.method("new_set_int32", new_set_int32);
  polymake.method("fill_jlarray_int32_from_set32", fill_jlarray_int32_from_set32);
  polymake.method("fill_jlarray_int64_from_set64", fill_jlarray_int64_from_set64);

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
  polymake.method("to_set_int64", to_set_int64);
  polymake.method("to_set_int32", to_set_int32);

  polymake.method("typeinfo_string", [](pm::perl::PropertyValue p){ PropertyValueHelper ph(p); return ph.get_typename(); });
  polymake.method("check_defined",[]( pm::perl::PropertyValue v){ return PropertyValueHelper(v).check_defined();});

  polymake.method("show_small_obj",show_integer);
  polymake.method("show_small_obj",show_rational);
  polymake.method("show_small_obj",show_vec_integer);
  polymake.method("show_small_obj",show_vec_rational);
  polymake.method("show_small_obj",show_mat_integer);
  polymake.method("show_small_obj",show_mat_rational);
  polymake.method("show_small_obj",show_set_int64);
  polymake.method("show_small_obj",show_set_int32);

  polymake.method("to_value",to_value<int>);
  polymake.method("to_value",to_value<pm::Integer>);
  polymake.method("to_value",to_value<pm::Rational>);
  polymake.method("to_value",to_value<pm::Vector<pm::Integer> >);
  polymake.method("to_value",to_value<pm::Vector<pm::Rational> >);
  polymake.method("to_value",to_value<pm::Matrix<pm::Integer> >);
  polymake.method("to_value",to_value<pm::Matrix<pm::Rational> >);
  polymake.method("to_value",to_value<pm::Set<int64_t> >);
  polymake.method("to_value",to_value<pm::Set<int32_t> >);
  polymake.method("to_value",to_value<pm::perl::OptionSet>);

//   polymake.method("cube",[](pm::perl::Value a1, pm::perl::Value a2, pm::perl::Value a3, pm::perl::OptionSet opt){ return polymake::polytope::cube<pm::QuadraticExtension<pm::Rational> >(a1,a2,a3,opt); });

}
