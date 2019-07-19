export @pm, call_function, call_method

import Base: convert, show

function perlobj(name::String, input_data::Dict{<:Union{String, Symbol},T}) where T
    perl_obj = pm_perl_Object(name)
    for value in input_data
        key = string(value[1])
        val = convert(PolymakeType, value[2])
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
    return take(obj, prop, convert(PolymakeType, val))
end

function Base.setproperty!(obj::pm_perl_Object, prop::Symbol, val)
    return take(obj, string(prop), convert(PolymakeType, val))
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
        lines = ["The return value contains $type_name which has not been wrapped yet;",
        "use `@pm Common.convert_to{wrapped_type}(...)` to convert to julia-understandable type."]
        @warn(join(lines, "\n"))
        return obj
    end
end

"""
    call_function(app::Symbol, func::Symbol, args...; void=false, kwargs...)

Call a polymake function `func` from application `app` with given arguments `args`.
If `void=true` the function is called in a void context. For example this is important for visualization.
"""
function call_function(app::Symbol, func::Symbol, args...; template_parameters::Array{String,1}=String[], void=false, unwrap=true, kwargs...)
    fname = "$app::$func"
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


"""
    @pm PolymakeModule.function_name{Template, parameters}(args)

This macro can be used to
 * create `polymake` Big Objects (such as polytopes)
 * call `polymake` functions with specific template parameters.

The expression passed to the macro has to be the fully qualified name (starting with the uppercase name of polymake application) of a `polymake` object or function, with template parameters enclosed in `{ ... }`.

# Examples
```jldoctest
julia> P = @pm Polytope.Polytope{QuadraticExtension}(POINTS=[1 0 0; 0 1 0])
type: Polytope<QuadraticExtension<Rational>>

POINTS
1 0 0
0 1 0



julia> @pm Common.convert_to{Float}(P)
type: Polytope<Float>

POINTS
1 0 0
0 1 0


CONE_AMBIENT_DIM
3



julia> @pm Tropical.Polytope{Max}(POINTS=[1 0 0; 0 1 0])
type: Polytope<Max, Rational>

POINTS
0 -1 -1
0 1 0



```
Note: the expression in `@pm` macro is parsed syntactically, so it has to be a valid `julia` expression. However template parameters **need not** to be defined in `julia`, but must be valid names of `polymake` property types. Nested types (such as `{QuadraticExtension{Rational}}`) are allowed.
"""
macro pm(expr)
    module_name, polymake_func, templates, args, kwargs = Meta.parse_function_call(expr)
    polymake_app = Meta.get_polymake_app_name(module_name)

    # poor-mans Big Object constructor detection
    if isuppercase(string(polymake_func)[1])
        polymake_func_name =
            Meta.pm_name_qualified(polymake_app, polymake_func, templates)
        return :(
            perlobj($polymake_func_name, $(esc.(args)...), $(esc.(kwargs)...))
            )
    else # we presume it's a function
        polymake_func_name =
            Meta.pm_name_qualified(polymake_app, polymake_func)

        return :(
            val = internal_call_function($polymake_func_name,
                $(string.(templates)),
                polymake_arguments($(esc.(args)...), $(esc.(kwargs)...)));
            convert_from_property_value(val)
        )
    end
end

macro register(expr)
    if expr.head == Symbol(".")
        module_name = expr.args[1]
        polymake_func = expr.args[2].value
    elseif expr.head == :call
        module_name, polymake_func, templates, args, kwargs = Meta.parse_function_call(expr)
    else
        throw(ArgumentError("Provide either qualified name or a call"))
    end
    polymake_app = Meta.get_polymake_app_name(module_name)

    pc = Meta.PolymakeFunction(polymake_func, string(polymake_func), string(polymake_app))

    :(
        @eval $(module_name) $(Meta.jl_code(pc));
        $(module_name).$(pc.jl_function)
    )
end

to_one_based_indexing(n::Number) = n + one(n)
to_zero_based_indexing(n::Number) = (n > zero(n) ? n - one(n) : throw(ArgumentError("Can't use negative index")))

for f in [:to_one_based_indexing, :to_zero_based_indexing]
    @eval begin
        $f(itr) = $f.(itr)
        $f(s::S) where S<:AbstractSet = S($f.(s))
    end
end
