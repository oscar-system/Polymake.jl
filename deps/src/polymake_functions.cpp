#include "polymake_includes.h"
#include "polymake_tools.h"
#include "polymake_caller.h"
#include "polymake_functions.h"

void initialize_polymake()
{
    try {
        if (data.main_polymake_session == nullptr) {
            data.main_polymake_session = new polymake::Main;
            data.main_polymake_session->shell_enable();
            data.main_polymake_scope = new polymake::perl::Scope(
                data.main_polymake_session->newScope());
            std::cout << data.main_polymake_session->greeting() << std::endl;
        };
    }
    catch (const std::exception& e) {
        jl_error(e.what());
    }
}

pm::perl::Object to_perl_object(pm::perl::PropertyValue v)
{
    pm::perl::Object obj;
    v >> obj;
    return v;
}
