#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_type_modules.h"


void polymake_module_add_lists(jlcxx::Module& polymake)
{
    auto type = polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>(
            "StdList", jlcxx::julia_type("Any", "Base"));

        type.apply<std::list<std::pair<pm::Int,pm::Int>>>([&polymake](auto wrapped) {
            typedef typename decltype(wrapped)::type WrappedT;
            typedef typename decltype(wrapped)::type::value_type elemType;

            wrapped.template constructor();
            wrapped.template constructor<WrappedT>();

            //Pattern to overwrite function in Base
            polymake.set_override_module(jl_base_module);

            wrapped.method("isempty", &WrappedT::empty);

            wrapped.method("empty!", [](WrappedT& L) {
                L.clear();
                return L;
            });

            wrapped.method("push!", [](WrappedT& L, elemType i) {
                L.push_back(i);
                return L;
            });

						wrapped.method("pushfirst!", [](WrappedT& L, elemType i) {
								L.push_front(i);
								return L;
						});

	    			wrapped.method("length", &WrappedT::size);

            polymake.unset_override_module();

            wrapped.method("show_small_obj", [](WrappedT& S) {
                return show_small_object<WrappedT>(S);
            });
        });

    polymake.method("to_list_pair_int", [](const pm::perl::PropertyValue& pv) {
        return to_SmallObject<std::list<std::pair<pm::Int, pm::Int>>>(pv);
    });

    polymake.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("ListIterator")
            .apply<WrappedStdListIterator<std::pair<pm::Int, pm::Int>>>(
            [](auto wrapped) {
                typedef typename decltype(wrapped)::type WrappedT;
                typedef typename decltype(wrapped)::type::value_type elemType;

                wrapped.method("beginiterator", [](std::list<elemType>& L) {
                    WrappedT result(L);
                    return result;
                });

                wrapped.method("increment", [](WrappedT& state) {
                    state.iterator++;
                });
                wrapped.method("get_element", [](WrappedT& state) {
                    auto elt = *(state.iterator);
                    return elt;
                });
                wrapped.method("isdone", [](std::list<elemType>& L,
                                            WrappedT&    state) {
                    return L.end() == state.iterator;
                });
            });

}
