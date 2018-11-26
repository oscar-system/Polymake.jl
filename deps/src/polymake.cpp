#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_integers.h"

#include "polymake_rationals.h"

#include "polymake_sets.h"

#include "polymake_arrays.h"

#include "polymake_caller.h"

Polymake_Data data{nullptr, nullptr};

JLCXX_MODULE define_module_polymake(jlcxx::Module& polymake)
{

  polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_perl_PropertyValue);
  polymake.add_type<pm::perl::OptionSet>("pm_perl_OptionSet");
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_perl_OptionSet);


  polymake.add_type<pm::perl::Object>("pm_perl_Object")
    .constructor<const std::string&>()
    .method("internal_give",[](pm::perl::Object p, const std::string& s){ return p.give(s); })
    .method("exists",[](pm::perl::Object p, const std::string& s){ return p.exists(s); })
    .method("properties",[](pm::perl::Object p){ std::string x = p.call_method("properties");
                                                 return x;
                                                });
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_perl_Object);

  polymake_module_add_integer(polymake);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Integer);

  polymake_module_add_rational(polymake);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Rational);

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Matrix", jlcxx::julia_type("AbstractMatrix", "Base"))
    .apply<
      pm::Matrix<pm::Integer>,
      pm::Matrix<pm::Rational>
    >([](auto wrapped){
        typedef typename decltype(wrapped)::type WrappedT;
        typedef typename decltype(wrapped)::type::value_type elemType;
        wrapped.template constructor<int32_t, int32_t>();
        wrapped.template constructor<int64_t, int64_t>();

        wrapped.method("_getindex", [](WrappedT& f, int64_t i, int64_t j){
          return elemType(f(i-1,j-1));
        });
        wrapped.method("_setindex!", [](WrappedT& M, elemType r, int64_t i, int64_t j){
            M(i-1,j-1)=r;
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
  polymake.method("to_matrix_Integer", [](pm::perl::PropertyValue pv){
    return to_SmallObject<pm::Matrix<pm::Integer>>(pv);
  });
  polymake.method("to_matrix_Rational", [](pm::perl::PropertyValue pv){
    return to_SmallObject<pm::Matrix<pm::Rational>>(pv);
  });
  polymake.method("to_string", [](pm::perl::PropertyValue pv){
    return to_SmallObject<std::string>(pv);
  });

  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Matrix_pm_Integer);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Matrix_pm_Rational);

  polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("pm_Vector", jlcxx::julia_type("AbstractVector", "Base"))
    .apply<
      pm::Vector<pm::Integer>,
      pm::Vector<pm::Rational>
    >([](auto wrapped){
        typedef typename decltype(wrapped)::type WrappedT;
        typedef typename decltype(wrapped)::type::value_type elemType;
        wrapped.template constructor<int32_t>();
        wrapped.template constructor<int64_t>();
        wrapped.method("_getindex", [](WrappedT& V, int64_t n){
          return elemType(V[n-1]);
        });
        wrapped.method("_setindex!",[](WrappedT& V, elemType val, int64_t n){
            V[n-1]=val;
        });
        wrapped.method("length", &WrappedT::size);
        wrapped.method("resize!",[](WrappedT& V, int64_t sz){
          V.resize(sz);
        });

        wrapped.method("take",[](pm::perl::Object p, const std::string& s, WrappedT& V){
            p.take(s) << V;
        });
        wrapped.method("show_small_obj", [](WrappedT& V){
          return show_small_object<WrappedT>(V);
        });
    });
  polymake.method("to_vector_Integer", [](pm::perl::PropertyValue pv){
    return to_SmallObject<pm::Vector<pm::Integer>>(pv);
  });
  polymake.method("to_vector_Rational", [](pm::perl::PropertyValue pv){
    return to_SmallObject<pm::Vector<pm::Rational>>(pv);
  });

  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Vector_pm_Integer);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Vector_pm_Rational);

  polymake.method("initialize_polymake", &initialize_polymake);
  polymake.method("application",[](const std::string x){
    data.main_polymake_session->set_application(x);
  });

  polymake.method("to_bool",[](pm::perl::PropertyValue p){ return static_cast<bool>(p);});
  polymake.method("to_int",[](pm::perl::PropertyValue p){ return static_cast<int64_t>(p);});
  polymake.method("to_double",[](pm::perl::PropertyValue p){ return static_cast<double>(p);});
  polymake.method("to_perl_object",&to_perl_object);

  polymake.method("typeinfo_string", [](pm::perl::PropertyValue p){
    PropertyValueHelper ph(p);
    return ph.get_typename();
  });

  polymake_module_add_set(polymake);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Set_Int64);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Set_Int32);

  polymake_module_add_array(polymake);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_Int32);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_Int64);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_pm_Integer);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_String);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_pm_Set_Int32);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_pm_Array_Int32);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_pm_Array_Int64);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_pm_Array_pm_Integer);
  POLYMAKE_INSERT_TYPE_IN_MAP(pm_Array_pm_Matrix_pm_Integer);

  polymake.method("shell_execute",[](const std::string x)
    {
      // FIXME: tuples with strings are broken in cxxwrap
      // return res;
      // instead we return an array of a bool and three strings now
      auto res = data.main_polymake_session->shell_execute(x);
      jl_value_t** output = new jl_value_t*[4];
      output[0] = jl_box_bool(std::get<0>(res));
      output[1] = jl_cstr_to_string(std::get<1>(res).c_str());
      output[2] = jl_cstr_to_string(std::get<2>(res).c_str());
      output[3] = jl_cstr_to_string(std::get<3>(res).c_str());
      return jlcxx::make_julia_array(output,4);
    });

  polymake.method("shell_complete",[](const std::string x)
    {
      auto res = data.main_polymake_session->shell_complete(x);
      std::vector<std::string> props = std::get<2>(res);
      jl_value_t** output = new jl_value_t*[props.size()+1];
      output[0] = jl_box_int64(std::get<0>(res));
      for (int i = 0; i < props.size(); ++i)
         output[i+1] = jl_cstr_to_string(props[i].c_str());
      return jlcxx::make_julia_array(output,props.size()+1);
    });

  polymake.method("take",[](pm::perl::Object p, const std::string& s, const std::string& t){
      p.take(s) << t;
  });
  polymake.method("take",[](pm::perl::Object p, const std::string& s, const pm::perl::PropertyValue& v){
      p.take(s) << v;
  });


  polymake_module_add_caller(polymake);

//   polymake.method("cube",[](pm::perl::Value a1, pm::perl::Value a2, pm::perl::Value a3, pm::perl::OptionSet opt){ return polymake::polytope::cube<pm::QuadraticExtension<pm::Rational> >(a1,a2,a3,opt); });

}
