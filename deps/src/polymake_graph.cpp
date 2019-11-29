#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_graph.h"

void polymake_module_add_graph(jlcxx::Module& polymake)
{
    // polymake
    //     .add_type<pm::graph::Graph>("pm_Graph",
    //                             jlcxx::julia_type("AbstractMatrix", "Base"))
    //     // .constructor<pm::graph::Graph>()
    //     // .constructor<pm::Matrix>()
    //     // .method("==", [](pm::Rational& a, pm::Rational& b) { return a == b; })
    //     .method("show_small_obj", [](pm::graph::Graph& S) {
    //             return show_small_object<pm::graph::Graph>(S);
    //     });
    //     polymake.method("to_pm_graph",
    //     [](pm::perl::PropertyValue pv) {
    //         return to_SmallObject<pm::graph::Graph>>(pv);
    // });

}
