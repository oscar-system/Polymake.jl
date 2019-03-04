#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_perl_objects.h"

#include "polymake_integers.h"

#include "polymake_rationals.h"

#include "polymake_sets.h"

#include "polymake_matrices.h"

#include "polymake_vectors.h"

#include "polymake_arrays.h"

#include "polymake_caller.h"

#include "polymake_type_translations.h"

Polymake_Data data{nullptr, nullptr};

JLCXX_MODULE define_module_polymake(jlcxx::Module& polymake)
{
    polymake_module_add_perl_object(polymake);

    polymake_module_add_integer(polymake);

    polymake_module_add_rational(polymake);

    polymake_module_add_matrix(polymake);

    polymake_module_add_vector(polymake);

    polymake_module_add_set(polymake);

    polymake_module_add_array(polymake);

    polymake.method("initialize_polymake", &initialize_polymake);
    polymake.method("application", [](const std::string x) {
        data.main_polymake_session->set_application(x);
    });

    polymake.method("shell_execute", [](const std::string x) {
        // FIXME: tuples with strings are broken in cxxwrap
        // return res;
        // instead we return an array of a bool and three strings now
        auto         res = data.main_polymake_session->shell_execute(x);
        jl_value_t** output = new jl_value_t*[4];
        output[0] = jl_box_bool(std::get<0>(res));
        output[1] = jl_cstr_to_string(std::get<1>(res).c_str());
        output[2] = jl_cstr_to_string(std::get<2>(res).c_str());
        output[3] = jl_cstr_to_string(std::get<3>(res).c_str());
        return jlcxx::make_julia_array(output, 4);
    });

    polymake.method("shell_complete", [](const std::string x) {
        auto res = data.main_polymake_session->shell_complete(x);
        std::vector<std::string> props = std::get<2>(res);
        jl_value_t**             output = new jl_value_t*[props.size() + 1];
        output[0] = jl_box_int64(std::get<0>(res));
        for (int i = 0; i < props.size(); ++i)
            output[i + 1] = jl_cstr_to_string(props[i].c_str());
        return jlcxx::make_julia_array(output, props.size() + 1);
    });

    polymake.method("shell_context_help", [](const std::string input, size_t pos=std::string::npos, bool full=false, bool html=false){
        std::vector<std::string> ctx_help =
            data.main_polymake_session->shell_context_help(input, pos, full, html);
        jl_value_t** doc_strings = new jl_value_t*[ctx_help.size()];
        for (int i=0; i < ctx_help.size(); ++i)
            doc_strings[i] = jl_cstr_to_string(ctx_help[i].c_str());
        return jlcxx::make_julia_array(doc_strings, ctx_help.size());
    });

#include "generated/map_inserts.h"

    polymake_module_add_caller(polymake);

    polymake_module_add_type_translations(polymake);

    //   polymake.method("cube",[](pm::perl::Value a1, pm::perl::Value a2,
    //   pm::perl::Value a3, pm::perl::OptionSet opt){ return
    //   polymake::polytope::cube<pm::QuadraticExtension<pm::Rational>
    //   >(a1,a2,a3,opt); });
}
