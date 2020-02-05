#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_sets.h"

template<> struct jlcxx::IsMirroredType<pm::operations::cmp> : std::false_type { };

void polymake_module_add_set(jlcxx::Module& polymake)
{
    polymake.add_type<pm::operations::cmp>("operations_cmp");

    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "Set", jlcxx::julia_type("AbstractSet", "Base"))
        .apply<pm::Set<pm::Int>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type             WrappedT;
            typedef typename decltype(wrapped)::type::value_type elemType;

            wrapped.template constructor<pm::Set<elemType>>();

            wrapped.method("_new_set", [](jlcxx::ArrayRef<elemType> A) {
                pm::Set<elemType> s{A.begin(), A.end()};
                return s;
            });

            wrapped.method("swap", &WrappedT::swap);

            wrapped.method("isempty", &WrappedT::empty);
            wrapped.method("length", &WrappedT::size);

            wrapped.method("empty!", [](WrappedT& S) {
                S.clear();
                return S;
            });
            wrapped.method("_isequal", [](WrappedT& S, WrappedT& T) { return S == T; });
            wrapped.method(
                "in", [](elemType i, WrappedT& S) { return S.contains(i); });

            wrapped.method("push!", [](WrappedT& S, elemType i) {
                S += i;
                return S;
            });

            wrapped.method("delete!", [](WrappedT& S, elemType i) {
                S -= i;
                return S;
            });

            wrapped.method("union!",
                           [](WrappedT& S, WrappedT& T) { return S += T; });
            wrapped.method("intersect!",
                           [](WrappedT& S, WrappedT& T) { return S *= T; });
            wrapped.method("setdiff!",
                           [](WrappedT& S, WrappedT& T) { return S -= T; });
            wrapped.method("symdiff!",
                           [](WrappedT& S, WrappedT& T) { return S ^= T; });

            wrapped.method(
                "union", [](WrappedT& S, WrappedT& T) { return WrappedT{S + T}; });
            wrapped.method("intersect", [](WrappedT& S, WrappedT& T) {
                return WrappedT{S * T};
            });
            wrapped.method("setdiff", [](WrappedT& S, WrappedT& T) {
                return WrappedT{S - T};
            });
            wrapped.method("symdiff", [](WrappedT& S, WrappedT& T) {
                return WrappedT{S ^ T};
            });

            wrapped.method("_getindex", [](WrappedT& S, WrappedT& T) {
                return WrappedT{pm::select(pm::wary(S), T)};
            });
            wrapped.method("range", [](elemType a, elemType b) {
                return WrappedT{pm::range(a, b)};
            });
            wrapped.method("sequence", [](elemType a, elemType c) {
                return WrappedT{pm::sequence(a, c)};
            });
            wrapped.method("scalar2set", [](elemType s) {
                return WrappedT{pm::scalar2set(s)};
            });
            wrapped.method("show_small_obj", [](WrappedT& S) {
                return show_small_object<WrappedT>(S);
            });
            wrapped.method("take",
                [](pm::perl::BigObject p, const std::string& s,
                    WrappedT& S){ p.take(s) << S; });
        });

    polymake.method("to_set_int", [](pm::perl::PropertyValue v) {
        return to_SmallObject<pm::Set<pm::Int>>(v);
    });

    polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("SetIterator")
        .apply<WrappedSetIterator<pm::Int>>(
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

    polymake.method("incl", [](pm::Set<pm::Int> s1, pm::Set<pm::Int> s2) {
        return pm::incl(s1, s2);
    });
}
