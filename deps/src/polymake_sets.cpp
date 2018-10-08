#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_sets.h"

void polymake_module_add_set(jlcxx::Module& polymake){
  polymake.add_type<pm::operations::cmp>("pm_operations_cmp");

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

      wrapped.method("increment", [](WrappedSetIter& state){
         state.iterator++;
      });
      wrapped.method("get_element", [](WrappedSetIter& state){
        auto elt = *(state.iterator);
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

  polymake.method("to_set_int64", to_set_int64);
  polymake.method("to_set_int32", to_set_int32);

  polymake.method("show_small_obj",show_set_int64);
  polymake.method("show_small_obj",show_set_int32);
}
