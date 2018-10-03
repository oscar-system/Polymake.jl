#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_sets.h"

Polymake_Data data;

JLCXX_MODULE define_module_polymake(jlcxx::Module& polymake)
{
  polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");
  polymake.add_type<pm::perl::OptionSet>("pm_perl_OptionSet");
  polymake.add_type<pm::perl::Value>("pm_perl_Value");


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
  polymake.method("check_defined",[]( pm::perl::PropertyValue v){ return PropertyValueHelper(v).check_defined();});

  polymake.method("show_small_obj",show_integer);
  polymake.method("show_small_obj",show_rational);
  polymake.method("show_small_obj",show_vec_integer);
  polymake.method("show_small_obj",show_vec_rational);
  polymake.method("show_small_obj",show_mat_integer);
  polymake.method("show_small_obj",show_mat_rational);


  polymake.method("to_value",to_value<int>);
  polymake.method("to_value",to_value<pm::Integer>);
  polymake.method("to_value",to_value<pm::Rational>);
  polymake.method("to_value",to_value<pm::Vector<pm::Integer> >);
  polymake.method("to_value",to_value<pm::Vector<pm::Rational> >);
  polymake.method("to_value",to_value<pm::Matrix<pm::Integer> >);
  polymake.method("to_value",to_value<pm::Matrix<pm::Rational> >);
  polymake.method("to_value",to_value<pm::perl::OptionSet>);

  polymake_module_add_set(polymake);

//   polymake.method("cube",[](pm::perl::Value a1, pm::perl::Value a2, pm::perl::Value a3, pm::perl::OptionSet opt){ return polymake::polytope::cube<pm::QuadraticExtension<pm::Rational> >(a1,a2,a3,opt); });

}
