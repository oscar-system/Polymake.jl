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

############### json parsing

########## structs

abstract type PolymakeCallable end

struct PolymakeFunction <: PolymakeCallable
    jl_function::Symbol
    pm_name::String
    app_name::String
    json::Dict{String, Any}

    PolymakeFunction(pm_name::String, app_name::String) =
        new(Symbol(pm_name), pm_name, app_name)
    PolymakeFunction(jl_name::Symbol, pm_name::String, app_name::String) =
        new(jl_name, pm_name, app_name)
    PolymakeFunction(jl_name::Symbol, pm_name::String, app_name::String, json_dict) =
        new(jl_name, pm_name, app_name, json_dict)
end

struct PolymakeMethod <: PolymakeCallable
    jl_function::Symbol
    pm_name::String
    app_name::String
    json::Dict{String, Any}

    PolymakeMethod(pm_name::String) =
        new(Symbol(pm_name), pm_name)
    PolymakeMethod(jl_name::Symbol, pm_name::String) =
        new(jl_name, pm_name)
    PolymakeMethod(jl_name::Symbol, pm_name::String, app_name, json_dict) =
        new(jl_name, pm_name, app_name, json_dict)
end

########## constructors

function PolymakeCallable(app_name::String, dict::Dict{String, Any},
    polymake_name=dict["name"], julia_name=Symbol(polymake_name))

    if haskey(dict, "method_of")
        return PolymakeMethod(julia_name, polymake_name, app_name, dict)
    else
        return PolymakeFunction(julia_name, polymake_name, app_name, dict)
    end
end

########## utils

pm_name(pc::PolymakeCallable) = pc.pm_name
pm_name_qualified(pc::PolymakeCallable) = pm_name_qualified(pc.app_name, pc.pm_name)

callable(::PolymakeFunction) = :internal_call_function
callable(::PolymakeMethod) = :internal_call_method
callable_void(::PolymakeFunction) = :internal_call_function_void
callable_void(::PolymakeMethod) = :internal_call_method_void


function Base.show(io::IO, pc::PolymakeCallable)
    println(io, typeof(pc), ":")
    for name in fieldnames(typeof(pc))
        if isdefined(pc, name)
            c = getfield(pc, name)
            content = "[$(typeof(c))] $c"
        else
            content = "#undef"
        end
        println(io, " • ", name, " → ", content)
    end
end

########## code generation

function jl_code(pf::PolymakeFunction)
    func_name = pm_name_qualified(pf)
    :(
        function $(pf.jl_function)(args...; template_parameters::Array{String,1}=String[], keep_PropertyValue=false, call_as_void=false, kwargs...)
            if call_as_void
                $(callable_void(pf))($func_name, template_parameters,
                    c_arguments(args...; kwargs...))
                return nothing
            else
                return_value = $(callable(pf))($func_name, template_parameters,
                    c_arguments(args...; kwargs...))
                if keep_PropertyValue
                    return return_value
                else
                    return convert_from_property_value(return_value)
                end
            end
        end;
        export $(pf.jl_function);
    )
end

function jl_code(pf::PolymakeMethod)
    func_name = pf.pm_name

    :(
        function $(pf.jl_function)(object::pm_perl_Object, args...; keep_PropertyValue=false, call_as_void=false, kwargs...)
            if call_as_void
                $(callable_void(pf))($func_name, object, c_arguments(args...; kwargs...))
                return nothing
            else
                return_value =
                $(callable(pf))($func_name, object, c_arguments(args...; kwargs...))
                if keep_PropertyValue
                    return return_value
                else
                    return convert_from_property_value(return_value)
                end
            end
        end;
        export $(pf.jl_function);
    )
end

end # of module Meta
