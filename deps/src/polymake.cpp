#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_sets.h"

#include "polymake_caller.h"

Polymake_Data data;

JLCXX_MODULE define_module_polymake(jlcxx::Module& polymake)
{

  polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_perl_PropertyValue);
  polymake.add_type<pm::perl::OptionSet>("pm_perl_OptionSet");
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_perl_OptionSet);


  polymake.add_type<pm::perl::Object>("pm_perl_Object")
    .constructor<const std::string&>()
    .method("give",[](pm::perl::Object p, const std::string& s){ return p.give(s); })
    .method("exists",[](pm::perl::Object p, const std::string& s){ return p.exists(s); })
    .method("properties",[](pm::perl::Object p){ std::string x = p.call_method("properties");
                                                 return x;
                                                });
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_perl_Object);

  polymake.add_type<pm::Integer>("pm_Integer", jlcxx::julia_type("Integer", "Base"))
    .constructor<int32_t>()
    .constructor<int64_t>()
    .method("show_small_obj", [](pm::Integer& i){
      return show_small_object<pm::Integer>(i);
    });
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Integer);
  polymake.method("new_pm_Integer",new_integer_from_bigint);

  polymake.add_type<pm::Rational>("pm_Rational", jlcxx::julia_type("Real", "Base"))
    .constructor<int32_t, int32_t>()
    .constructor<int64_t, int64_t>()
    .template constructor<pm::Integer, pm::Integer>()
    .method("numerator",[](pm::Rational r){ return pm::Integer(numerator(r)); })
    .method("denominator",[](pm::Rational r){ return pm::Integer(denominator(r));})
    .method("show_small_obj", [](pm::Rational& r){
      return show_small_object<pm::Rational>(r);
    });

  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Rational);

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Matrix", jlcxx::julia_type("AbstractMatrix", "Base"))
    .apply<pm::Matrix<pm::Integer>, pm::Matrix<pm::Rational>>([](auto wrapped){
        typedef typename decltype(wrapped)::type WrappedT;
        typedef typename decltype(wrapped)::type::value_type elemType;
        // typedef typename decltype(wrapped)::foo X;
        wrapped.template constructor<int64_t, int64_t>();
        
        wrapped.method("getindex", [](WrappedT& f, int64_t i, int64_t j){ return elemType(f(i,j));});
        wrapped.method("setindex!", [](WrappedT& M, int64_t i, int64_t j, elemType r){
            M(i,j)=r;
        });
        wrapped.method("rows",&WrappedT::rows);
        wrapped.method("cols",&WrappedT::cols);
        wrapped.method("resize",[](WrappedT& M, int64_t i, int64_t j){ M.resize(i,j); });
        
        wrapped.method("take",[](pm::perl::Object p, const std::string& s, WrappedT& M){
            p.take(s) << M;
        });
        wrapped.method("show_small_obj", [](WrappedT& M){
          return show_small_object<WrappedT>(M);
        });
    });
  POLYMAKE_INSERT_TYPE_IN_MAP_SINGLE_TEMPLATE(pm_Matrix,pm_Integer);
  POLYMAKE_INSERT_TYPE_IN_MAP_SINGLE_TEMPLATE(pm_Matrix,pm_Rational);

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Vector", jlcxx::julia_type("AbstractVector", "Base"))
    .apply<pm::Vector<pm::Integer>, pm::Vector<pm::Rational>>([](auto wrapped){
        typedef typename decltype(wrapped)::type WrappedT;
        typedef typename decltype(wrapped)::type::value_type elemType;
        // typedef typename decltype(wrapped)::foo X;
        wrapped.template constructor<int64_t>();
        wrapped.method("getindex", [](WrappedT& V, int64_t n){
          return elemType(V[n]);
        });
        wrapped.method("setindex!",[](WrappedT& V, int64_t n, elemType v){
            V[n]=v;
        });
        wrapped.method("length", &WrappedT::size);
        wrapped.method("resize",[](WrappedT& V, int64_t sz){
          V.resize(sz);
        });
        
        wrapped.method("take",[](pm::perl::Object p, const std::string& s, WrappedT& V){
            p.take(s) << V;
        });
        wrapped.method("show_small_obj", [](WrappedT& V){
          return show_small_object<WrappedT>(V);
        });
    });
  POLYMAKE_INSERT_TYPE_IN_MAP_SINGLE_TEMPLATE(pm_Vector,pm_Integer);
  POLYMAKE_INSERT_TYPE_IN_MAP_SINGLE_TEMPLATE(pm_Vector,pm_Rational);

  polymake.method("init", &initialize_polymake);
  polymake.method("call_func_0args",&call_func_0args);
  polymake.method("call_func_1args",&call_func_1args);
  polymake.method("call_func_2args",&call_func_2args);
  polymake.method("application",[](const std::string x){ data.main_polymake_session->set_application(x); });

  polymake.method("to_int",[](pm::perl::PropertyValue p){ return static_cast<int64_t>(p);});
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
  polymake.method("check_defined",[]( pm::perl::PropertyValue v){ return PropertyValueHelper(v).check_defined();});

  polymake_module_add_set(polymake);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Set_Int64);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Set_Int32);

  polymake_module_add_caller(polymake);

//   polymake.method("cube",[](pm::perl::Value a1, pm::perl::Value a2, pm::perl::Value a3, pm::perl::OptionSet opt){ return polymake::polytope::cube<pm::QuadraticExtension<pm::Rational> >(a1,a2,a3,opt); });

}
