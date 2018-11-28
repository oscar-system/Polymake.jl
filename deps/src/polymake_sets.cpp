#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_sets.h"

void polymake_module_add_set(jlcxx::Module& polymake)
{
    polymake.add_type<pm::operations::cmp>("pm_operations_cmp");

    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "pm_Set", jlcxx::julia_type("AbstractSet", "Base"))
        .apply<pm::Set<int32_t>, pm::Set<int64_t>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type             pm_Set;
            typedef typename decltype(wrapped)::type::value_type elemType;

            wrapped.template constructor<pm::Set<elemType>>();

            wrapped.method("_new_set", [](jlcxx::ArrayRef<elemType> A) {
                pm::Set<elemType> s{A.begin(), A.end()};
                return s;
            });

            wrapped.method("swap", &pm_Set::swap);

            wrapped.method("isempty", &pm_Set::empty);
            wrapped.method("length", &pm_Set::size);

            wrapped.method("empty!", [](pm_Set& S) {
                S.clear();
                return S;
            });
            wrapped.method("==", [](pm_Set& S, pm_Set& T) { return S == T; });
            wrapped.method(
                "in", [](elemType i, pm_Set& S) { return S.contains(i); });

            wrapped.method("push!", [](pm_Set& S, elemType i) {
                S += i;
                return S;
            });

            wrapped.method("delete!", [](pm_Set& S, elemType i) {
                S -= i;
                return S;
            });

            wrapped.method("union!",
                           [](pm_Set& S, pm_Set& T) { return S += T; });
            wrapped.method("intersect!",
                           [](pm_Set& S, pm_Set& T) { return S *= T; });
            wrapped.method("setdiff!",
                           [](pm_Set& S, pm_Set& T) { return S -= T; });
            wrapped.method("symdiff!",
                           [](pm_Set& S, pm_Set& T) { return S ^= T; });

            wrapped.method(
                "union", [](pm_Set& S, pm_Set& T) { return pm_Set{S + T}; });
            wrapped.method("intersect", [](pm_Set& S, pm_Set& T) {
                return pm_Set{S * T};
            });
            wrapped.method("setdiff", [](pm_Set& S, pm_Set& T) {
                return pm_Set{S - T};
            });
            wrapped.method("symdiff", [](pm_Set& S, pm_Set& T) {
                return pm_Set{S ^ T};
            });

            wrapped.method("getindex", [](pm_Set& S, pm_Set& T) {
                return pm_Set{pm::select(pm::wary(S), T)};
            });
            wrapped.method("range", [](elemType a, elemType b) {
                return pm_Set{pm::range(a, b)};
            });
            wrapped.method("sequence", [](elemType a, elemType c) {
                return pm_Set{pm::sequence(a, c)};
            });
            wrapped.method("scalar2set", [](elemType s) {
                return pm_Set{pm::scalar2set(s)};
            });
            wrapped.method("show_small_obj", [](pm_Set& S) {
                return show_small_object<pm_Set>(S);
            });
        });

    polymake.method("to_set_int32", [](pm::perl::PropertyValue v) {
        return to_SmallObject<pm::Set<int32_t>>(v);
    });
    polymake.method("to_set_int64", [](pm::perl::PropertyValue v) {
        return to_SmallObject<pm::Set<int64_t>>(v);
    });

    polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("SetIterator")
        .apply<WrappedSetIterator<int32_t>, WrappedSetIterator<int64_t>>(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type WrappedSetIter;
                typedef typename decltype(wrapped)::type::value_type elemType;
                wrapped.method("beginiterator", [](pm::Set<elemType>& S) {
                    auto result = WrappedSetIterator<elemType>{S};
                    return result;
                });

                wrapped.method("increment", [](WrappedSetIter& state) {
                    state.iterator++;
                });
                wrapped.method("get_element", [](WrappedSetIter& state) {
                    auto elt = *(state.iterator);
                    return elt;
                });
                wrapped.method("isdone", [](pm::Set<elemType>& S,
                                            WrappedSetIter&    state) {
                    return S.end() == state.iterator;
                });
            });

    polymake.method("incl", [](pm::Set<int32_t> s1, pm::Set<int32_t> s2) {
        return pm::incl(s1, s2);
    });
    polymake.method("incl", [](pm::Set<int32_t> s1, pm::Set<int64_t> s2) {
        return pm::incl(s1, s2);
    });
    polymake.method("incl", [](pm::Set<int64_t> s1, pm::Set<int32_t> s2) {
        return pm::incl(s1, s2);
    });
    polymake.method("incl", [](pm::Set<int64_t> s1, pm::Set<int64_t> s2) {
        return pm::incl(s1, s2);
    });
}
