#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

Polymake_Data data;

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
