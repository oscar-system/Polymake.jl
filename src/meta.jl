module Meta
import JSON
import Polymake: appname_module_dict, module_appname_dict

pm_name_qualified(app_name, func_name) = "$app_name::$func_name"

function pm_name_qualified(app_name, func_name, templates)
    qname = pm_name_qualified(app_name, func_name)
    templs = length(templates) > 0 ? "<$(join(templates, ","))>" : ""
    return qname*templs
end

function get_polymake_app_name(mod::Symbol)
    haskey(module_appname_dict, mod) || throw("Module '$mod' not registered in Polymake.jl.")
    polymake_app = module_appname_dict[mod]
    return polymake_app
end

end # of module Meta