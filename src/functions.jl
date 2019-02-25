export @pm, call_function, call_method

import Base: convert, show

function perlobj(name::String, input_data::Dict{<:Union{String, Symbol},T}) where T
    perl_obj = pm_perl_Object(name)
    for value in input_data
        key = string(value[1])
        val = convert_to_pm(value[2])
        take(perl_obj,key,val)
    end
    return perl_obj
end

function perlobj(name::String, input_data::Pair{<:Union{Symbol,String}}...; kwargsdata...)
    obj = pm_perl_Object(name)
    for (key, val) in input_data
        setproperty!(obj, string(key), val)
    end
    for (key, val) in kwargsdata
        setproperty!(obj, string(key), val)
    end
    return obj
end

const module_appname_dict = Dict(
  :Common  => :common,
  :Fans  => :fan,
  :Fulton  => :fulton,
  :Graphs  => :graph,
  :Groups  => :group,
  :Ideals  => :ideal,
  :Matroids  => :matroid,
  :Polytopes  => :polytope,
  :Topaz  => :topaz,
  :Tropical  => :tropical
)

function qualified_func_name(app_name, func_name, template_params=:Symbol[])
    name = "$app_name::$func_name"
    if length(template_params) > 0
        name *= "<$(join(template_params, ","))>"
    end
    return name
end

macro pm(expr)
    @assert expr.head == :call
    func = expr.args[1] # called function
    args = expr.args[2:end] # its arguments

    template_types = Symbol[]
    # grab template parameters if present
    if func.head == :curly
        template_types = func.args[2:end]
        func = func.args[1]
    end

    # for now we want the function name to be fully qualified:
    @assert func.head == Symbol('.')
    haskey(module_appname_dict, func.args[1]) || throw("Module '$(func.args[1])' not in Polymake.jl.")
    polymake_app = module_appname_dict[func.args[1]]
    polymake_func = func.args[2].value

    polymake_func_name = qualified_func_name(polymake_app, polymake_func, template_types)
    ex = :(Polymake.perlobj($polymake_func_name, $(esc(args...))))
    return ex
end

const WrappedTypes = Dict(
    Symbol("int") => to_int,
    Symbol("double") => to_double,
    Symbol("bool") => to_bool,
    Symbol("std::string") => to_string,
    Symbol("undefined") => x -> nothing,
)

function fill_wrapped_types!(wrapped_types_dict, function_type_list)
    function_names = function_type_list[1:2:end]
    type_names = function_type_list[2:2:end]
    for (fn, tn) in zip(function_names, type_names)
        fns = Symbol(fn)
        tn = replace(tn," "=>"")
        @eval $wrapped_types_dict[Symbol($tn)] = Polymake.$fns
    end
    return wrapped_types_dict
end

Base.propertynames(p::Polymake.pm_perl_Object) = Symbol.(Polymake.complete_property(p, ""))

function Base.setproperty!(obj::pm_perl_Object, prop::String, val)
    return take(obj, prop, convert_to_pm(val))
end

function Base.setproperty!(obj::pm_perl_Object, prop::Symbol, val)
    return take(obj, string(prop), convert_to_pm(val))
end

struct Visual
    obj::Polymake.pm_perl_PropertyValue
end

function convert_from_property_value(obj::Polymake.pm_perl_PropertyValue)
    type_name = Polymake.typeinfo_string(obj,true)
    T = Symbol(replace(type_name," "=>""))
    if haskey(WrappedTypes, T)
        f = WrappedTypes[T]
        return f(obj)
    elseif startswith(type_name,"Visual::")
        return Visual(obj)
    else
        @warn("The return value contains $type_name which has not been wrapped yet")
        return obj
    end
end

"""
    call_function(func::Symbol, args...; void=false, kwargs...)

Call a polymake function with the given `func` name and given arguments `args`.
If `void=true` the function is called in a void context. For example this is important for visualization.
"""
function call_function(func::Symbol, args...; template_parameters::Array{String,1}=String[], void=false, unwrap=true, kwargs...)
    fname = string(func)
    cargs = Any[args...]
    if isempty(kwargs)
        if void
            internal_call_function_void(fname, template_parameters, cargs)
            return
        else
            ret = internal_call_function(fname, template_parameters, cargs)
        end
    else
        if void
            internal_call_function_void(fname, template_parameters, cargs, OptionSet(kwargs))
            return
        else
            ret = internal_call_function(fname, template_parameters, cargs, OptionSet(kwargs))
        end
    end
    if unwrap
        return convert_from_property_value(ret)
    else
        return ret
    end
end

"""
    call_method(obj::pm_perl_Object, func::Symbol, args...; kwargs...)

Call a polymake method on the object `obj` with the given `func` name and given arguments `args`.
If `void=true` the function is called in a void context. For example this is important for visualization.
"""
function call_method(obj, func::Symbol, args...; void=false, unwrap=true, kwargs...)
    fname = string(func)
    cargs = Any[args...]
    if isempty(kwargs)
        if void
            internal_call_method_void(fname, obj, cargs)
            return
        else
            ret = internal_call_method(fname, obj, cargs)
        end
    else
        if void
            internal_call_method_void(fname, obj, cargs, OptionSet(kwargs))
            return
        else
            ret = internal_call_method(fname, obj, cargs, OptionSet(kwargs))
        end
    end
    if unwrap
        return convert_from_property_value(ret)
    else
        return ret
    end
end

function give(obj::Polymake.pm_perl_Object, prop::String)
    return_obj = try
        internal_give(obj, prop)
    catch ex
        throw(PolymakeError(ex.msg))
    end
    return convert_from_property_value(return_obj)
end

Base.getproperty(obj::pm_perl_Object, prop::Symbol) = give(obj, string(prop))

Base.show(io::IO, obj::pm_perl_Object) = print(io, properties(obj))
function Base.show(io::IO, ::MIME"text/plain", obj::SmallObject)
    print(io, show_small_obj(obj))
end
# fallback for non-wrapped types
function Base.show(io::IO, ::MIME"text/plain", pv::pm_perl_PropertyValue)
    print(io, to_string(pv))
end
function Base.show(io::IO, ::MIME"text/plain", a::pm_Array{pm_perl_Object})
    print(io, "pm_Array{pm_perl_Object} of size ",length(a))
end
Base.show(io::IO, obj::SmallObject) = show(io, MIME("text/plain"), obj)

function Base.show(io::IO, v::Visual)
    # IJulia renders all possible mimes, so frontend can decide on
    # the way to display the output.
    # This `if` keeps the browser from opening a new tab
    if !(isdefined(Main, :IJulia) && Main.IJulia.inited)
        show(io,MIME("text/plain"),v.obj)
    end
end

function Base.show(io::IO,::MIME"text/html",v::Visual)
     print(io,_get_visual_string_threejs(v))
end

function Base.show(io::IO,::MIME"text/svg+xml",v::Visual)
    print(io,_get_visual_string_svg(v))
end
