#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_type_modules.h"


void polymake_module_add_pairs(jlcxx::Module& polymake)
{

    auto type = polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>, jlcxx::TypeVar<2>>>(
            "StdPair", jlcxx::julia_type("Any", "Base" ));

        type.apply<std::pair<pm::Int,pm::Int>>([&polymake](auto wrapped) {
            typedef typename decltype(wrapped)::type WrappedT;

            wrapped.template constructor();
            wrapped.template constructor<int64_t, int64_t>();

            //Pattern to overwrite function in Base
            polymake.set_override_module(jl_base_module);

	    			wrapped.method("first", [](WrappedT& P) {
                return P.first;
            });

            wrapped.method("last", [](WrappedT& P) {
                return P.second;
            });

	    			polymake.unset_override_module();

						wrapped.method("show_small_obj", [](WrappedT& S) {
								return show_small_object<WrappedT>(S);
						});
        });

    polymake.method("to_pair_int_int", [](const pm::perl::PropertyValue& pv) {
        return to_SmallObject<std::pair<pm::Int, pm::Int>>(pv);
    });

}
