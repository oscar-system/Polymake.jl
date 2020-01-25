module Meta
import JSON
import Polymake: appname_module_dict, module_appname_dict, shell_context_help
import Polymake: Rational, PolymakeType

struct UnparsablePolymakeFunction <: Exception
    msg::String
    UnparsablePolymakeFunction(function_name, json) = new("Cannot parse function: $function_name\n$json")
end

############### fuctions used at runtime (imported to App modules)

function polymake_arguments(args...; kwargs...)
    isempty(kwargs) && return Any[ convert.(PolymakeType, args)... ]
    return Any[ convert.(PolymakeType, args); OptionSet(kwargs) ]
end

function get_docs(input::AbstractString; full::Bool=true, html::Bool=false)
    pos = UInt(max(length(input)-1, 0))
    return shell_context_help(input, pos, full, html)
end

function pm_name_qualified(app_name, func_name, templates=String[])
    isempty(templates) && return "$app_name::$func_name"
    return "$app_name::$func_name<$(join(templates, ","))>"
end

translate_type_to_pm_string(::Type{Bool}) = "bool"
translate_type_to_pm_string(::Type{Int64}) = "pm::Int"
translate_type_to_pm_string(::Type{<:AbstractFloat}) = "Float"
translate_type_to_pm_string(::Type{<:Rational}) = "Rational"
translate_type_to_pm_string(::Type{<:Base.Rational}) = "Rational"
translate_type_to_pm_string(::Type{<:Base.Integer}) = "Integer"
translate_type_to_pm_string(::typeof(min)) = "Min"
translate_type_to_pm_string(::typeof(max)) = "Max"

translate_type_to_pm_string(T) = throw(DomainError(T, "$T has been passed as a type parameter but no translation to a C++ template was defined. You may define such translation by appropriately extending
    `Polymake.Meta.translate_type_to_pm_string`."))

function get_polymake_app_name(mod::Symbol)
    haskey(module_appname_dict, mod) || throw("Module '$mod' not registered in Polymake.jl. If polmake application is present add the name to Polymake.module_appname_dict.")
    polymake_app = module_appname_dict[mod]
    return polymake_app
end

############### macro helpers

function recursive_replace(str::AbstractString, replacement_pairs)
    for (p,r) in replacement_pairs
        str = replace(str, p=>r)
    end
    return str
end

replace_braces(str) = recursive_replace(str, ["{"=>"<", "}"=>">"])

function extract_args_kwargs(expr::Expr)
    kwarg_idx = findfirst(a -> a isa Expr && a.head == :kw, expr.args)
    kwarg_idx === nothing && return expr.args[2:end], Any[]
    return expr.args[2:kwarg_idx-1], expr.args[kwarg_idx:end]
end

function extract_module_function(expr::Expr)
    @assert expr.head == Symbol('.')
    return expr.args[1], expr.args[2].value
end

function deconstruct_head(expr::Expr)
    @assert expr.head == :call
    func = expr.args[1] # called function

    # func its either
    # `call(:curly, call(:., app, func_name), templates)`
    # or
    # `call(:., app, func_name)`

    if func.head == :curly
        module_name, func_name = extract_module_function(func.args[1])
        templates = replace_braces.(string.(func.args[2:end]))
    elseif func.head == Symbol('.')
        module_name, func_name = extract_module_function(func)
        templates = String[]
    else
        throw(ArgumentError("Cannot deconstruct the expression: $expr"))
    end
    return module_name, func_name, templates
end

function parse_function_call(expr)
    @assert expr.head == :call

    module_name, func_name, templates = deconstruct_head(expr)
        args, kwargs = extract_args_kwargs(expr)

    #      Symbol     , Symbol   , String   , Any[], Any[]
    return module_name, func_name, templates, args , kwargs
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
        PolymakeFunction(Symbol(lowercase(pm_name)), pm_name, app_name)

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

    PolymakeMethod(pm_name::String, app_name::String) =
        PolymakeMethod(Symbol(lowercase(pm_name)), pm_name, app_name)

    PolymakeMethod(jl_name::Symbol, pm_name::String, app_name::String) =
        new(jl_name, pm_name, app_name)

    PolymakeMethod(jl_name::Symbol, pm_name::String, app_name, json_dict) =
        new(jl_name, pm_name, app_name, json_dict)
end

struct PolymakeObject <: PolymakeCallable
    jl_function::Symbol
    pm_name::String
    app_name::String
    json::Dict{String, Any}

    PolymakeObject(pm_name::String, app_name::String) =
        PolymakeObject(Symbol(pm_name), pm_name, app_name)

    PolymakeObject(jl_name::Symbol, pm_name::String, app_name::String) =
        new(jl_name, pm_name, app_name)

    PolymakeObject(jl_name::Symbol, pm_name::String, app_name::String, json_dict) =
        new(jl_name, pm_name, app_name, json_dict)
end

struct PolymakeApp
    jl_module::Symbol
    pm_name::String
    callables::Vector{PolymakeCallable}
    objects::Vector{PolymakeObject}
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

function PolymakeObject(app_name::String, dict::Dict{String, Any},
    polymake_name=dict["name"], julia_name=Symbol(polymake_name))

    return PolymakeObject(julia_name, polymake_name, app_name, dict)
end

function PolymakeApp(jl_module::Symbol, app_json::Dict{String, Any})
    app_name = app_json["app"]

    if haskey(app_json, "functions")
        for f in app_json["functions"]
            if !haskey(f, "name")
                @warn UnparsablePolymakeFunction("$app_name::$f", f)
            end
        end

        callables = [PolymakeCallable(app_name,f) for f in app_json["functions"] if haskey(f, "name")]

        callables = unique(pc -> pm_name(pc), callables)
    else
        callables = PolymakeCallable[]
    end

    if haskey(app_json, "objects")
        objects = [PolymakeObject(app_name, obj) for obj in app_json["objects"] if haskey(obj, "name")]

        objects = unique(pc -> pm_name(pc), objects)
    else
        objects = PolymakeObject[]
    end

    return PolymakeApp(jl_module, app_name, callables, objects)
end

function PolymakeApp(module_name::Symbol, json_file::String)
    @assert isfile(json_file)
    app_json = JSON.Parser.parsefile(json_file)
    return PolymakeApp(module_name, app_json)
end

########## utils

Base.lowercase(s::Symbol) = Symbol(lowercase(string(s)))

pm_app(pc::PolymakeCallable) = pc.app_name

pm_name(pc::PolymakeCallable) = pc.pm_name
pm_name(app::PolymakeApp) = app.pm_name
pm_name_qualified(pc::PolymakeCallable) = pm_name_qualified(pm_app(pc), pm_name(pc))

jl_symbol(pc::PolymakeCallable) = lowercase(pc.jl_function)
jl_symbol(pc::PolymakeObject) = pc.jl_function
jl_module_name(pa::PolymakeApp) = pa.jl_module

callable(::PolymakeFunction) = :internal_call_function
callable(::PolymakeMethod) = :internal_call_method
callable_void(::PolymakeFunction) = :internal_call_function_void
callable_void(::PolymakeMethod) = :internal_call_method_void

docstring(obj::PolymakeObject) = get(obj.json, "help", "")
istemplated(obj::PolymakeObject) = haskey(obj.json, "params")
templates(obj::PolymakeObject) = Symbol.(get(obj.json, "params", String[]))

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

function Base.show(io::IO, app::PolymakeApp)
    println(io, "Parsed polymake application $(pm_name(app)) as Polymake.$(jl_module_name(app)) containing:")
    println(io, "  $(length(app.callables)) functions:")
    println(io, join((jl_symbol(f) for f in app.callables), ", ", " and "))
    println(io, "  $(length(app.objects)) Big Objects:")
    println(io, join((jl_symbol(obj) for obj in app.objects), ", ", " and "))
end

########## code generation

function jl_code(pf::PolymakeFunction)
    func_name = pm_name_qualified(pf)

    return quote
        function $(jl_symbol(pf))(args...; template_parameters::Array{String,1}=String[], keep_PropertyValue=false, call_as_void=false, kwargs...)
            if call_as_void
                $(callable_void(pf))($func_name, template_parameters,
                    polymake_arguments(args...; kwargs...))
                return nothing
            else
                return_value = $(callable(pf))($func_name, template_parameters,
                    polymake_arguments(args...; kwargs...))
                if keep_PropertyValue
                    return return_value
                else
                    return convert_from_property_value(return_value)
                end
            end
        end;
        function $(Base.Docs).getdoc(::typeof($(jl_symbol(pf))))
            docstrs = get_docs($func_name, full=true)
            return PolymakeDocstring(join(docstrs, "\n\n---\n\n"))
        end;
        export $(jl_symbol(pf));
    end
end

function jl_code(pf::PolymakeMethod)
    func_name = pm_name(pf)

    return quote
        function $(jl_symbol(pf))(object::BigObject, args...; keep_PropertyValue=false, call_as_void=false, kwargs...)
            if call_as_void
                $(callable_void(pf))($func_name, object, polymake_arguments(args...; kwargs...))
                return nothing
            else
                return_value =
                $(callable(pf))($func_name, object, polymake_arguments(args...; kwargs...))
                if keep_PropertyValue
                    return return_value
                else
                    return convert_from_property_value(return_value)
                end
            end
        end;
        export $(jl_symbol(pf));
    end
end

function jl_constructor(jl_name::Symbol, pm_name::String, app_name::String)
    return quote
        function $(jl_name)(args...; kwargs...)
            # name created at compile-time
            return bigobj($(pm_name_qualified(app_name, pm_name)),
                args..., kwargs...)
        end
    end
end

function jl_constructor(jl_name::Symbol, pm_name::String, app_name::String, templates)
    return quote
        function $(jl_name){$(templates...)}(args...; kwargs...) where {$(templates...)}
            Ts = translate_type_to_pm_string.([$(templates...)])
            # name created at run-time
            pm_full_name = pm_name_qualified($(app_name), $(pm_name), Ts)
            return bigobj(pm_full_name, args..., kwargs...)
        end
    end
end

jl_constructor(obj::PolymakeObject, templates) =
    jl_constructor(jl_symbol(obj), pm_name(obj), pm_app(obj), templates)

jl_constructor(obj::PolymakeObject) =
    jl_constructor(jl_symbol(obj), pm_name(obj), pm_app(obj))

function jl_code(obj::PolymakeObject)
    jl_object_name = jl_symbol(obj)
    pm_object_name = pm_name_qualified(obj.app_name, pm_name(obj))

    if istemplated(obj)
        Ts = templates(obj)
        templated_constructors = [
            jl_constructor(obj, Ts[1:i]) for i in 1:length(Ts)
        ]

        struct_def = quote
            struct $(jl_object_name){$(Ts...)}
                # inner templated constructors:
                $(templated_constructors...)
                # inner template-less constructor
                $(jl_constructor(obj))
            end;
        end # of quote
    else
        struct_def = quote
            struct $(jl_symbol(obj))
                # inner template-less constructor
                $(jl_constructor(obj))
            end;
        end # of quote
    end

    return quote
        $struct_def;
        Base.Docs.getdoc(::Type{$(jl_symbol(obj))}) = PolymakeDocstring($(docstring(obj)))
    end
end

struct PolymakeDocstring
    s::String
end
# if someone wants to implement something prettier, overload this
Base.show(io::IO, doc::PolymakeDocstring) = print(io, doc.s)

module_imports() = quote
    import Polymake: convert_from_property_value,
    internal_call_function, internal_call_method,
    bigobj, BigObject, OptionSet
    import Polymake.Meta: PolymakeDocstring, pm_name_qualified, translate_type_to_pm_string, get_docs, polymake_arguments
end

function jl_code(pa::PolymakeApp)
    fn_code = jl_code.(pa.callables)
    obj_code = jl_code.(pa.objects)
    return :(
        module $(jl_module_name(pa))
        $(module_imports())
        $(fn_code...)
        $(obj_code...)
        end
    )
end

end # of module Meta
