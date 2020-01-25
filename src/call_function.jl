export @pm, call_function, call_method

"""
    call_function(app::Symbol, func::Symbol, args...; void=false, kwargs...)

Call a polymake function `func` from application `app` with given arguments `args`.
"""
function call_function(app::Symbol, func::Symbol, args...; template_parameters::Base.Array{String,1}=String[], unwrap=true, kwargs...)
    fname = "$app::$func"
    cargs = Any[args...]
    if isempty(kwargs)
        ret = internal_call_function(fname, template_parameters, cargs)
    else
        ret = internal_call_function(fname, template_parameters, cargs, OptionSet(kwargs))
    end
    if unwrap
        return convert_from_property_value(ret)
    else
        return ret
    end
end

"""
    call_method(obj::BigObject, func::Symbol, args...; kwargs...)

Call a polymake method on the object `obj` with the given `func` name and given arguments `args`.
"""
function call_method(obj, func::Symbol, args...; unwrap=true, kwargs...)
    fname = string(func)
    cargs = Any[args...]
    if isempty(kwargs)
        ret = internal_call_method(fname, obj, cargs)
    else
        ret = internal_call_method(fname, obj, cargs, OptionSet(kwargs))
    end
    if unwrap
        return convert_from_property_value(ret)
    else
        return ret
    end
end

"""
    @pm polymakemodule.function_name{Template, parameters}(args)

This macro can be used to
 * create `polymake` Big Objects (such as polytopes)
 * call `polymake` functions with specific template parameters.

The expression passed to the macro has to be the fully qualified name (starting with the uppercase name of polymake application) of a `polymake` object or function, with template parameters enclosed in `{ ... }`.

# Examples
```jldoctest
julia> P = @pm polytope.Polytope{QuadraticExtension}(POINTS=[1 0 0; 0 1 0])
type: Polytope<QuadraticExtension<Rational>>

POINTS
1 0 0
0 1 0



julia> @pm common.convert_to{Float}(P)
type: Polytope<Float>

POINTS
1 0 0
0 1 0


CONE_AMBIENT_DIM
3



julia> @pm tropical.Polytope{Max}(POINTS=[1 0 0; 0 1 0])
type: Polytope<Max, Rational>

POINTS
0 -1 -1
0 1 0



```
Note: the expression in `@pm` macro is parsed syntactically, so it has to be a valid `julia` expression. However template parameters **need not** to be defined in `julia`, but must be valid names of `polymake` property types. Nested types (such as `{QuadraticExtension{Rational}}`) are allowed.
"""
macro pm(expr)
    module_name, polymake_func, templates, args, kwargs = try
        Meta.parse_function_call(expr)
    catch ex
        throw(ArgumentError("Can not parse the expression passed to @pm macro:\n$expr\n Only `@pm app.func{template, parameters}(KEY=val)` syntax is recognized"))
        rethrow(ex)
    end
    polymake_app = Meta.get_polymake_app_name(module_name)

    # poor-mans Big Object constructor detection
    if isuppercase(string(polymake_func)[1])
        polymake_func_name =
            Meta.pm_name_qualified(polymake_app, polymake_func, templates)
        return :(
            bigobj($polymake_func_name, $(esc.(args)...), $(esc.(kwargs)...))
            )
    else # we presume it's a function
        polymake_func_name =
            Meta.pm_name_qualified(polymake_app, polymake_func)
        return :(
            let val = internal_call_function($polymake_func_name,
                $templates,
                Meta.polymake_arguments($(esc.(args)...), $(esc.(kwargs)...)));
                convert_from_property_value(val)
            end
        )
    end
end
