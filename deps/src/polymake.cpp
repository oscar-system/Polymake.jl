#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_caller.h"

#include "polymake_type_modules.h"

#include "generated/type_declarations.h"

Polymake_Data data{nullptr, nullptr};

JLCXX_MODULE define_module_polymake(jlcxx::Module& polymake)
{
    polymake_module_add_bigobject(polymake);

    polymake_module_add_integer(polymake);

    polymake_module_add_rational(polymake);

    polymake_module_add_matrix(polymake);

    polymake_module_add_pairs(polymake);

    polymake_module_add_lists(polymake);

    polymake_module_add_vector(polymake);

    polymake_module_add_set(polymake);

    polymake_module_add_sparsevector(polymake);;

    auto array_type = polymake_module_add_array(polymake);

    polymake_module_add_incidencematrix(polymake);

    polymake_module_add_sparsematrix(polymake);

    polymake_module_add_tropicalnumber(polymake);

    polymake_module_add_polynomial(polymake);

    polymake_module_add_direct_calls(polymake);
    polymake_module_add_beneath_beyond(polymake);

    polymake_module_add_array_polynomial(polymake, array_type);

    polymake.method("initialize_polymake", &initialize_polymake);
    polymake.method("application", [](const std::string x) {
        data.main_polymake_session->set_application(x);
    });

    polymake.method("_shell_execute", [](const std::string x) {
        return data.main_polymake_session->shell_execute(x);
    });

    polymake.method("shell_complete", [](const std::string x) {
        auto res = data.main_polymake_session->shell_complete(x);
        return std::tuple<int64_t, std::vector<std::string>>{
            std::get<0>(res),
            std::get<2>(res)
        };
    });

    polymake.method("shell_context_help", [](
        const std::string& input,
        size_t pos=std::string::npos,
        bool full=false,
        bool html=false){
        std::vector<std::string> ctx_help =
            data.main_polymake_session->shell_context_help(input, pos, full, html);
        return ctx_help;
    });

    polymake.method("set_preference", [](const std::string x) {
        return data.main_polymake_session->set_preference(x);
    });

#include "generated/map_inserts.h"

    polymake_module_add_caller(polymake);

    polymake_module_add_type_translations(polymake);

    //   polymake.method("cube",[](pm::perl::Value a1, pm::perl::Value a2,
    //   pm::perl::Value a3, pm::perl::OptionSet opt){ return
    //   polymake::polytope::cube<pm::QuadraticExtension<pm::Rational>
    //   >(a1,a2,a3,opt); });
}
